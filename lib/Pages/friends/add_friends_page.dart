import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  FirebaseApp? firebaseApp;

  @override
  void initState() {
    super.initState();
    searchUsers('');
  }

  /// 🔹 Écoute en temps réel les amis et demandes d'amis
  Stream<DocumentSnapshot> fetchCurrentUserStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();
  }

  Future<void> sendPushNotification(String token, String senderName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("❌ Utilisateur non connecté !");
        return;
      }

      print("🔹 Token utilisateur : ${user.uid}");
      HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendFriendRequestNotification');

      print("🔹 Envoi de la notification...");

      final response = await callable.call({
        "token": token,
        "senderName": senderName,
      });

      print("🔹 Réponse de la fonction : ${response.data}");

      if (response.data['success'] == true) {
        print("✅ Notification envoyée avec succès !");
      } else {
        print("❌ Erreur : ${response.data['error']}");
      }
    } catch (e) {
      print("❌ Exception lors de l'envoi de la notification : $e");
    }
  }

  Future<void> searchUsers(String query) async {
    setState(() {
      isLoading = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    QuerySnapshot querySnapshot;
    if (query.isEmpty) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('pseudo', isGreaterThanOrEqualTo: query)
          .where('pseudo', isLessThanOrEqualTo: '$query\uf8ff')
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .get();
    }

    setState(() {
      searchResults = querySnapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      isLoading = false;
    });
  }

  Future<void> sendFriendRequest(String friendUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final senderName = currentUserDoc.data()?['pseudo'] ?? "Un utilisateur";

      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();
      final friendToken = friendDoc.data()?['fcmToken'];

      await FirebaseFirestore.instance.collection('users').doc(friendUid).update({
        'pending_approval': FieldValue.arrayUnion([currentUser.uid]),
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'friend_requests': FieldValue.arrayUnion([friendUid]),
      });

      print("friend token : $friendToken et senderName : $senderName");

      if (friendToken != null) {
        await sendPushNotification(friendToken, senderName);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Demande d\'ami envoyée.',
            style: AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Erreur lors de l\'envoi : $e',
            style: AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text('Ajouter des amis', style: theme.titleMedium),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un utilisateur par pseudo...',
                    prefixIcon: Icon(Icons.search, color: theme.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: searchUsers,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: fetchCurrentUserStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(child: Text('Aucun utilisateur trouvé.'));
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final currentUserFriends = userData['friends'] ?? [];
                    final currentUserFriendRequests = userData['friend_requests'] ?? [];

                    return ListView.separated(
                      itemCount: searchResults.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        final friendUid = user['id'];

                        String buttonText = currentUserFriends.contains(friendUid)
                            ? 'Ami'
                            : currentUserFriendRequests.contains(friendUid)
                                ? 'En attente'
                                : 'Ajouter';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user['photoUrl'] ?? ''),
                          ),
                          title: Text('${user['surname']} ${user['name']}'),
                          subtitle: Text(user['pseudo'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: buttonText == 'Ajouter'
                                ? () => sendFriendRequest(friendUid)
                                : null,
                            child: Text(buttonText),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
