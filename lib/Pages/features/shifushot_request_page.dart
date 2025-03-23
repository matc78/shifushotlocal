// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../theme/app_theme.dart';

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

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    final friendUids = List<String>.from(userDoc.data()?['friends'] ?? []);

    final fetchedFriends = await Future.wait(friendUids.map((uid) async {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
    final senderDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final senderName = senderDoc.data()?['name'] ?? "Quelqu'un";

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'utilisateur n'a pas activé les notifications.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('sendShifushotNotification');

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
        final currentCount = snapshot.exists ? (snapshot.data()?['count'] ?? 0) as int : 0;
        transaction.set(notifRef, {'count': currentCount + 1, 'name': selectedFriendData!['name']});
      });

      // === Mise à jour du compteur chez le RECEVEUR ===
      final receivedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(selectedFriendId)
          .collection('shifushot_notifs_received')
          .doc(currentUser.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(receivedRef);
        final currentCount = snapshot.exists ? (snapshot.data()?['count'] ?? 0) as int : 0;

        transaction.set(receivedRef, {
          'count': currentCount + 1,
          'name': senderName, // nom du joueur connecté
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de Shifushot envoyée !')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Demande de Shifushot"),
        centerTitle: true,
        backgroundColor: theme.background,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedFriendId,
              decoration: const InputDecoration(labelText: "Choisir un ami"),
              items: friends.map((friend) {
                return DropdownMenuItem<String>(
                  value: friend['id'],
                  child: Text(friend['name'] ?? 'Inconnu'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFriendId = value;
                  selectedFriendData = friends.firstWhere((f) => f['id'] == value);
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedFriendData != null)
              Text(
                (selectedFriendData!['notifications']?['shifushot_requests'] ?? false)
                    ? '✅ Notifications activées. \n\nSi la notification n’est pas reçue, dis à ton pote de\nvérifier les paramètres de notification de l’application sur le téléphone.'
                    : '❌ Notifications désactivées. \n\nDemande à ton ami d’activer les notifications dans les paramètres de son téléphone\nou dans les notifications de son profil shifushot',
                style: theme.bodyMedium,
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: sendShifushotRequest,
              icon: const Icon(Icons.send),
              label: const Text("Envoyer la demande"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}