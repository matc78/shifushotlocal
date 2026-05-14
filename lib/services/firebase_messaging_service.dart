import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  String? _initializedForUid;
  bool _listenersAttached = false;

  Future<void> initializeForUser(GlobalKey<NavigatorState> navigatorKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_initializedForUid == user.uid) return;
    _initializedForUid = user.uid;

    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission(alert: true, badge: true, sound: true);

    final token = await fcm.getToken();
    if (token != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        await userRef.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'fcmToken': token,
          'notifications': {
            'enabled': true,
            'friend_requests': true,
            'shifushot_requests': true,
          },
          'friends': [],
          'friend_requests': [],
          'pending_approval': [],
        });
      } else {
        await userRef.update({'fcmToken': token});
      }
    }

    if (_listenersAttached) return;
    _listenersAttached = true;

    fcm.onTokenRefresh.listen((newToken) async {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(current.uid)
            .update({'fcmToken': newToken});
      }
    });

    FirebaseMessaging.onMessage.listen((message) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        // ignore: use_build_context_synchronously
        context: ctx,
        builder: (dialogCtx) => AlertDialog(
          title: Text(message.notification?.title ?? 'Notification'),
          content: Text(message.notification?.body ?? 'Nouveau message'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  void reset() {
    _initializedForUid = null;
  }
}
