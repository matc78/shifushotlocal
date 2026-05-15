import 'package:flutter_test/flutter_test.dart';
import 'package:shifushotlocal/services/user_repository.dart';

class _FakeUserRepository implements UserRepository {
  final Map<String, Map<String, dynamic>> _store = {};
  final Set<String> _pseudos = {};

  void addUser(String uid, Map<String, dynamic> data) {
    _store[uid] = data;
    final pseudo = data['pseudo'];
    if (pseudo is String) _pseudos.add(pseudo);
  }

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async => _store[uid];

  @override
  Stream<Map<String, dynamic>?> watchUser(String uid) =>
      Stream.value(_store[uid]);

  @override
  Future<bool> isPseudoTaken(String pseudo) async => _pseudos.contains(pseudo);

  @override
  Future<void> updatePhotoUrl(String uid, String url) async {
    final user = _store[uid];
    if (user != null) user['photoUrl'] = url;
  }

  @override
  Future<int> countUsers() async => _store.length;
}

void main() {
  group('UserRepositoryLocator', () {
    tearDown(() {
      // Leave a fake in place; constructing FirestoreUserRepository here
      // would touch Firebase.
      UserRepositoryLocator.override(_FakeUserRepository());
    });

    test('override swaps the singleton', () {
      final fake = _FakeUserRepository();
      UserRepositoryLocator.override(fake);
      expect(identical(UserRepositoryLocator.instance, fake), isTrue);
    });
  });

  group('FakeUserRepository (sanity)', () {
    test('round-trips data through the repository contract', () async {
      final fake = _FakeUserRepository();
      fake.addUser('u1', {'pseudo': 'noob1', 'photoUrl': 'a.jpg'});
      fake.addUser('u2', {'pseudo': 'noob2', 'photoUrl': 'b.jpg'});

      expect(await fake.getUser('u1'), {'pseudo': 'noob1', 'photoUrl': 'a.jpg'});
      expect(await fake.getUser('missing'), isNull);
      expect(await fake.isPseudoTaken('noob1'), isTrue);
      expect(await fake.isPseudoTaken('unknown'), isFalse);
      expect(await fake.countUsers(), 2);

      await fake.updatePhotoUrl('u1', 'new.jpg');
      expect((await fake.getUser('u1'))!['photoUrl'], 'new.jpg');
    });

    test('watchUser emits the current value', () async {
      final fake = _FakeUserRepository();
      fake.addUser('u', {'pseudo': 'x'});
      final value = await fake.watchUser('u').first;
      expect(value, {'pseudo': 'x'});
    });
  });
}
