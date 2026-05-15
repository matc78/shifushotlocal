import 'package:cloud_firestore/cloud_firestore.dart';

/// Read/write access to the `users` Firestore collection.
abstract class UserRepository {
  Future<Map<String, dynamic>?> getUser(String uid);
  Stream<Map<String, dynamic>?> watchUser(String uid);
  Future<bool> isPseudoTaken(String pseudo);
  Future<void> updatePhotoUrl(String uid, String url);
  Future<int> countUsers();
}

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  @override
  Stream<Map<String, dynamic>?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) => doc.data());
  }

  @override
  Future<bool> isPseudoTaken(String pseudo) async {
    final snap = await _users.where('pseudo', isEqualTo: pseudo).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<void> updatePhotoUrl(String uid, String url) async {
    await _users.doc(uid).update({'photoUrl': url});
  }

  @override
  Future<int> countUsers() async {
    final snap = await _users.count().get();
    return snap.count ?? 0;
  }
}

class UserRepositoryLocator {
  UserRepositoryLocator._();
  static UserRepository _instance = FirestoreUserRepository();
  static UserRepository get instance => _instance;
  static void override(UserRepository repo) => _instance = repo;
}
