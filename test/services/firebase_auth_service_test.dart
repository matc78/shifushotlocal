import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/services/auth_service.dart';

// Exercises the real FirebaseAuthService class against in-memory fakes
// from firebase_auth_mocks / fake_cloud_firestore. Validates the actual
// integration logic (Firestore writes, error code translation, doc
// provisioning) that the simple AuthService fake in auth_service_test.dart
// can't reach.

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late FirebaseAuthService service;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = FakeFirebaseFirestore();
    service = FirebaseAuthService(auth: auth, firestore: firestore);
  });

  group('signInWithEmail', () {
    test('returns AuthSuccess for a verified user', () async {
      auth = MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: false,
          uid: 'u1',
          email: 'a@b.c',
          isEmailVerified: true,
        ),
      );
      service = FirebaseAuthService(auth: auth, firestore: firestore);

      final result = await service.signInWithEmail(
        email: 'a@b.c',
        password: 'pw12345!',
      );

      expect(result, isA<AuthSuccess>());
      expect((result as AuthSuccess).user.uid, 'u1');
      expect(auth.currentUser, isNotNull);
    });

    test('returns AuthEmailNotVerified for an unverified user', () async {
      auth = MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: false,
          uid: 'u2',
          email: 'x@y.z',
          isEmailVerified: false,
        ),
      );
      service = FirebaseAuthService(auth: auth, firestore: firestore);

      final result = await service.signInWithEmail(
        email: 'x@y.z',
        password: 'pw',
      );
      expect(result, isA<AuthEmailNotVerified>());
    });
  });

  group('createAccountWithEmail', () {
    test('creates an auth user AND a Firestore user doc', () async {
      final result = await service.createAccountWithEmail(
        email: 'new@user.com',
        password: 'Strong1!',
        pseudo: 'newbie',
        name: 'Doe',
        surname: 'Jane',
        gender: 'Autre',
      );

      expect(result, isA<AuthSuccess>());
      final user = (result as AuthSuccess).user;
      expect(user.email, 'new@user.com');
      expect(result.isNewUser, isTrue);

      final doc = await firestore.collection('users').doc(user.uid).get();
      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['pseudo'], 'newbie');
      expect(data['name'], 'Doe');
      expect(data['gender'], 'Autre');
      // Default scaffolding fields:
      expect(data['friends'], isEmpty);
      expect((data['notifications'] as Map)['enabled'], isTrue);
    });
  });

  group('signOut', () {
    test('clears the current user from FirebaseAuth', () async {
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'signedIn'),
      );
      service = FirebaseAuthService(auth: auth, firestore: firestore);

      expect(auth.currentUser, isNotNull);
      await service.signOut();
      expect(auth.currentUser, isNull);
    });
  });
}
