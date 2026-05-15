import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/services/auth_service.dart';

/// Minimal in-memory AuthService stand-in. Demonstrates the testability win
/// from the service-layer refactor: callers (pages) only depend on
/// AuthService, so a fake like this swaps in via AuthServiceLocator.override.
class _FakeAuthService implements AuthService {
  _FakeAuthService({
    this.signInResult,
    this.createAccountResult,
    this.googleResult,
  });

  AuthResult? signInResult;
  AuthResult? createAccountResult;
  AuthResult? googleResult;

  int signInCalls = 0;
  int createCalls = 0;
  int googleCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<User?> get userChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    return signInResult ?? const AuthFailure('unset', 'no result configured');
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
    createCalls++;
    return createAccountResult ??
        const AuthFailure('unset', 'no result configured');
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    googleCalls++;
    return googleResult ?? const AuthFailure('unset', 'no result configured');
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  group('AuthResult sealed hierarchy', () {
    test('AuthSuccess carries the user and isNewUser flag', () {
      const r = AuthSuccess(_dummyUser, isNewUser: true);
      expect(r, isA<AuthResult>());
      expect(r.isNewUser, isTrue);
    });

    test('pattern matching covers every variant', () {
      String describe(AuthResult r) => switch (r) {
            AuthSuccess() => 'success',
            AuthEmailNotVerified() => 'unverified',
            AuthCancelled() => 'cancelled',
            AuthFailure(:final code) => 'failure:$code',
          };
      expect(describe(const AuthSuccess(_dummyUser)), 'success');
      expect(describe(const AuthEmailNotVerified()), 'unverified');
      expect(describe(const AuthCancelled()), 'cancelled');
      expect(describe(const AuthFailure('x', 'msg')), 'failure:x');
    });
  });

  group('AuthServiceLocator', () {
    tearDown(() {
      // Leave a no-op fake in place; constructing FirebaseAuthService here
      // would touch Firebase.initializeApp which isn't available in unit
      // tests. Each test in this group sets its own fake explicitly.
      AuthServiceLocator.override(_FakeAuthService());
    });

    test('override swaps the singleton', () {
      final fake = _FakeAuthService();
      AuthServiceLocator.override(fake);
      expect(identical(AuthServiceLocator.instance, fake), isTrue);
    });

    test('fake records calls and returns configured results', () async {
      final fake = _FakeAuthService(
        signInResult: const AuthEmailNotVerified(),
      );
      AuthServiceLocator.override(fake);

      final result = await AuthServiceLocator.instance.signInWithEmail(
        email: 'a@b.c',
        password: 'p',
      );

      expect(result, isA<AuthEmailNotVerified>());
      expect(fake.signInCalls, 1);
    });
  });
}

// User is final but we only need a non-null reference for the sealed-class
// destructuring tests. Real tests of FirebaseAuthService go through
// firebase_auth_mocks or an integration harness — out of scope here.
const User _dummyUser = _UnreachableUser();

class _UnreachableUser implements User {
  const _UnreachableUser();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('dummy user — not meant to be called');
}
