import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Outcomes that the UI cares about, kept independent of Firebase types so
/// callers don't have to import firebase_auth just to read an error.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user, {this.isNewUser = false});
  final User user;
  final bool isNewUser;
}

class AuthEmailNotVerified extends AuthResult {
  const AuthEmailNotVerified();
}

class AuthCancelled extends AuthResult {
  const AuthCancelled();
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.code, this.message);
  final String code;
  final String message;
}

/// Thin abstraction over Firebase Auth + Firestore "users" collection.
/// All Firebase imports stay in this file; widgets call the service.
abstract class AuthService {
  Stream<User?> get userChanges;
  User? get currentUser;

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
    required String pseudo,
    required String name,
    required String surname,
    String? gender,
  });

  Future<AuthResult> signInWithGoogle();

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static const _defaultPhotoUrl =
      'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<User?> get userChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthFailure('no-user', 'Aucun utilisateur retourné.');
      }
      if (!user.emailVerified) {
        return const AuthEmailNotVerified();
      }
      return AuthSuccess(user);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(e.code, _humanReadable(e));
    }
  }

  @override
  Future<AuthResult> createAccountWithEmail({
    required String email,
    required String password,
    required String pseudo,
    required String name,
    required String surname,
    String? gender,
  }) async {
    try {
      // Pseudo uniqueness check is done at the call site since the UI may
      // want to surface it as a field error rather than a snackbar.
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        return const AuthFailure('no-user', 'Aucun utilisateur retourné.');
      }
      await user.sendEmailVerification();
      await _users.doc(user.uid).set({
        'email': email,
        'pseudo': pseudo,
        'name': name,
        'surname': surname,
        'gender': gender,
        'createdAt': Timestamp.now(),
        'emailVerified': false,
        'friends': [],
        'pending_approval': [],
        'friend_requests': [],
        'photoUrl': _defaultPhotoUrl,
        'notifications': {
          'enabled': true,
          'friend_requests': true,
          'shifushot_requests': true,
        },
      });
      return AuthSuccess(user, isNewUser: true);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(e.code, _humanReadable(e));
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return const AuthCancelled();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        return const AuthFailure('no-user', 'Échec de la connexion Google.');
      }
      final doc = await _users.doc(user.uid).get();
      final isNewUser = !doc.exists;
      if (isNewUser) {
        await _provisionGoogleUserDoc(user);
      }
      return AuthSuccess(user, isNewUser: isNewUser);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(e.code, _humanReadable(e));
    } catch (e) {
      return AuthFailure('unknown', e.toString());
    }
  }

  Future<void> _provisionGoogleUserDoc(User user) async {
    final email = user.email ?? '';
    final baseName = email.split('@').first;
    final existing = await _users.get();
    final pseudo = 'noob${existing.docs.length + 1}';
    await _users.doc(user.uid).set({
      'email': email,
      'pseudo': pseudo,
      'name': baseName,
      'surname': baseName,
      'photoUrl': user.photoURL ?? _defaultPhotoUrl,
      'gender': 'Autre',
      'createdAt': Timestamp.now(),
      'friends': [],
      'pending_approval': [],
      'friend_requests': [],
      'notifications': {
        'enabled': true,
        'friend_requests': true,
        'shifushot_requests': true,
      },
    });
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Not a Google user (or sign-out hiccup) — fall through.
    }
    await _auth.signOut();
  }

  String _humanReadable(FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => 'Utilisateur introuvable.',
      'wrong-password' => 'Mot de passe incorrect.',
      'email-already-in-use' => 'Cet email est déjà utilisé.',
      'weak-password' => 'Le mot de passe est trop faible.',
      'invalid-email' => 'Email invalide.',
      'too-many-requests' => 'Trop de tentatives, réessaie plus tard.',
      'network-request-failed' => 'Pas de connexion réseau.',
      _ => e.message ?? 'Erreur inconnue (${e.code}).',
    };
  }
}

/// Process-wide singleton. Replace via `AuthServiceLocator.override(...)` in
/// tests if you ever want to inject a fake.
class AuthServiceLocator {
  AuthServiceLocator._();
  static AuthService _instance = FirebaseAuthService();
  static AuthService get instance => _instance;
  static void override(AuthService service) => _instance = service;
}
