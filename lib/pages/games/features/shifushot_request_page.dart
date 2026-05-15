import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class ShifushotRequestPage extends StatefulWidget {
  const ShifushotRequestPage({super.key});

  @override
  State<ShifushotRequestPage> createState() => _ShifushotRequestPageState();
}

class _ShifushotRequestPageState extends State<ShifushotRequestPage> {
  String? selectedFriendId;
  Map<String, dynamic>? selectedFriendData;
  List<Map<String, dynamic>> friends = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final friendUids = List<String>.from(userDoc.data()?['friends'] ?? []);

    final fetchedFriends = await Future.wait(friendUids.map((uid) async {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return {'id': uid, ...?doc.data()};
    }));

    setState(() {
      friends = fetchedFriends;
    });
  }

  Future<void> sendShifushotRequest() async {
    if (selectedFriendId == null || selectedFriendData == null) return;

    final token = selectedFriendData!['fcmToken'];
    final currentUser = FirebaseAuth.instance.currentUser;
    final senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final senderName = senderDoc.data()?['name'] ?? "Quelqu'un";
    if (!mounted) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("L'utilisateur n'a pas activé les notifications.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendShifushotNotification');

      await callable.call({
        'token': token,
        'senderName': senderName,
      });

      // === Mise à jour du compteur dans Firestore ===
      final notifRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('shifushot_notifs')
          .doc(selectedFriendId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(notifRef);
        final currentCount =
            snapshot.exists ? (snapshot.data()?['count'] ?? 0) as int : 0;
        transaction.set(notifRef,
            {'count': currentCount + 1, 'name': selectedFriendData!['name']});
      });

      // === Mise à jour du compteur chez le RECEVEUR ===
      final receivedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(selectedFriendId)
          .collection('shifushot_notifs_received')
          .doc(currentUser.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivedRef);
        final currentCount =
            snapshot.exists ? (snapshot.data()?['count'] ?? 0) as int : 0;

        transaction.set(receivedRef, {
          'count': currentCount + 1,
          'name': senderName, // nom du joueur connecté
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de Shifushot envoyée !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final enabled =
        selectedFriendData?['notifications']?['shifushot_requests'] ?? false;

    return AppShell(
      title: 'ShifuShot ?',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedFriendId,
              dropdownColor: theme.surface,
              style: theme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Choisis un ami'),
              items: friends
                  .map((friend) => DropdownMenuItem<String>(
                        value: friend['id'],
                        child: Text(friend['name'] ?? 'Inconnu'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedFriendId = value;
                  selectedFriendData =
                      friends.firstWhere((f) => f['id'] == value);
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedFriendData != null)
              SectionCard(
                child: Row(
                  children: [
                    Icon(
                      enabled
                          ? Icons.check_circle_rounded
                          : Icons.notifications_off_rounded,
                      color: enabled ? theme.primary : theme.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        enabled
                            ? 'Notifications activées. Si elle n\'arrive pas, demande à ton pote de vérifier les paramètres notif sur son tel.'
                            : 'Notifications désactivées. Demande-lui de les activer dans son profil ou les paramètres système.',
                        style: theme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            GradientButton(
              label: isLoading ? 'Envoi…' : 'Envoyer la demande',
              icon: Icons.send_rounded,
              onPressed: isLoading ? null : sendShifushotRequest,
            ),
          ],
        ),
      ),
    );
  }
}
