import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

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
        debugPrint("❌ Utilisateur non connecté !");
        return;
      }

      debugPrint("🔹 Token utilisateur : ${user.uid}");
      HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'us-central1')
              .httpsCallable('sendFriendRequestNotification');

      debugPrint("🔹 Envoi de la notification...");

      final response = await callable.call({
        "token": token,
        "senderName": senderName,
      });

      debugPrint("🔹 Réponse de la fonction : ${response.data}");

      if (response.data['success'] == true) {
        debugPrint("✅ Notification envoyée avec succès !");
      } else {
        debugPrint("❌ Erreur : ${response.data['error']}");
      }
    } catch (e) {
      debugPrint("❌ Exception lors de l'envoi de la notification : $e");
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
      // 🔹 Données de l'utilisateur actuel
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final senderName = currentUserDoc.data()?['pseudo'] ?? "Un utilisateur";

      // 🔹 Données du destinataire
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();
      final friendData = friendDoc.data() ?? {};
      final friendToken = friendData['fcmToken'];
      final notifPrefs = friendData['notifications'] as Map<String, dynamic>?;

      // 🔹 Ajouter dans pending et friend_requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .update({
        'pending_approval': FieldValue.arrayUnion([currentUser.uid]),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'friend_requests': FieldValue.arrayUnion([friendUid]),
      });

      debugPrint("friend token : $friendToken et senderName : $senderName");

      // ✅ Vérifier si le destinataire a activé les notifs
      final wantsFriendRequestNotif = (notifPrefs?['enabled'] ?? false) &&
          (notifPrefs?['friend_requests'] ?? false);

      if (friendToken != null && wantsFriendRequestNotif) {
        await sendPushNotification(friendToken, senderName);
      } else {
        debugPrint(
            "🔕 Le destinataire a désactivé les notifications de demandes d'ami.");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            'Demande d\'ami envoyée.',
            style:
                AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Erreur lors de l\'envoi : $e',
            style:
                AppTheme.of(context).bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AppShell(
      title: 'Ajouter des amis',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: theme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Rechercher par pseudo…',
                prefixIcon: Icon(Icons.search_rounded, color: theme.textMuted),
              ),
              onChanged: searchUsers,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: fetchCurrentUserStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.separated(
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, __) => const SkeletonListTile(),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun utilisateur trouvé',
                      subtitle: 'Essaie un autre pseudo.',
                    );
                  }
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final friends = userData['friends'] ?? [];
                  final requests = userData['friend_requests'] ?? [];

                  if (searchResults.isEmpty) {
                    return const EmptyState(
                      icon: Icons.person_search_rounded,
                      title: 'Aucun résultat',
                      subtitle: 'Tape un pseudo pour rechercher.',
                    );
                  }
                  return ListView.separated(
                    itemCount: searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final user = searchResults[i];
                      final uid = user['id'];
                      final isFriend = friends.contains(uid);
                      final isPending = requests.contains(uid);
                      final label = isFriend
                          ? 'Ami'
                          : isPending
                              ? 'Attente'
                              : 'Ajouter';
                      final photoUrl = user['photoUrl'] as String?;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: theme.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.surfaceAlt,
                              backgroundImage:
                                  (photoUrl != null && photoUrl.isNotEmpty)
                                      ? CachedNetworkImageProvider(photoUrl)
                                      : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? Icon(Icons.person, color: theme.textMuted)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(user['pseudo'] ?? '',
                                      style: theme.bodyLarge.copyWith(
                                        color: theme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      )),
                                  const SizedBox(height: 2),
                                  Text(
                                      '${user['surname'] ?? ''} ${user['name'] ?? ''}'
                                          .trim(),
                                      style: theme.bodyMedium),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 36,
                              child: !isFriend && !isPending
                                  ? GradientButton(
                                      label: label,
                                      onPressed: () => sendFriendRequest(uid),
                                      expanded: false,
                                      height: 36,
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: theme.surfaceAlt,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusPill),
                                        border: Border.all(color: theme.border),
                                      ),
                                      child: Text(label,
                                          style: theme.bodyMedium.copyWith(
                                            color: theme.textMuted,
                                            fontWeight: FontWeight.w700,
                                          )),
                                    ),
                            ),
                          ],
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
    );
  }
}
