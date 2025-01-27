import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({Key? key}) : super(key: key);

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Future<List<Map<String, dynamic>>> friendsFuture;
  late Future<List<Map<String, dynamic>>> pendingApprovalsFuture;


  @override
  void initState() {
    super.initState();
    friendsFuture = fetchFriends();
    pendingApprovalsFuture = fetchPendingApprovals();
  }

  Future<List<Map<String, dynamic>>> fetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final List<dynamic> friendsUids = userDoc.data()?['friends'] ?? [];
    if (friendsUids.isEmpty) return [];

    final List<Map<String, dynamic>> friendsData = [];
    for (final uid in friendsUids) {
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (friendDoc.exists) {
        friendsData.add(friendDoc.data() as Map<String, dynamic>);
      }
    }

    return friendsData;
  }

  Future<String?> fetchFriendUid(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final List<dynamic> friendsUids = userDoc.data()?['friends'] ?? [];
    if (index < friendsUids.length) {
      return friendsUids[index];
    }

    return null;
  }

   Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final List<dynamic> pendingApprovalUids = userDoc.data()?['pending_approval'] ?? [];
    if (pendingApprovalUids.isEmpty) return [];

    final List<Map<String, dynamic>> pendingApprovalsData = [];
    for (final uid in pendingApprovalUids) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        pendingApprovalsData.add(userDoc.data() as Map<String, dynamic>);
      }
    }

    return pendingApprovalsData;
  }

  Future<String?> fetchPendingApprovalUid(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Récupérer le document de l'utilisateur actuel
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Obtenir la liste des UID des pending approvals
    final List<dynamic> pendingApprovalUids = userDoc.data()?['pending_approval'] ?? [];
    if (index < pendingApprovalUids.length) {
      return pendingApprovalUids[index]; // Retourner l'UID correspondant à l'index
    }

    return null; // Aucun UID trouvé pour cet index
  }

  void refreshFriends() {
    setState(() {
      friendsFuture = fetchFriends();
    });
  }

  void refreshPendingApprovals() {
    setState(() {
      pendingApprovalsFuture = fetchPendingApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        title: Text('Khoya Page', style: theme.titleMedium),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/addFriend');
                  },
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  label: Text('Ajouter Khoya', style: theme.buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                buildFriendsSection(theme),
                const SizedBox(height: 20),
                buildPendingApprovalsSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildFriendsSection(AppTheme theme) {
    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Liste amis', style: theme.titleLarge),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'Autant d\'amis que de "ç" dans surf ?',
                          style: theme.bodyMedium.copyWith(color: theme.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        Image.network(
                          'https://mathsamoi.com/wp-content/uploads/2019/10/061-image-entrc3a9e-1.png?w=640',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  );
                }

                final friendsList = snapshot.data!;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friendsList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final friend = friendsList[index];
                    //final friendUid = friend['uid'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          friend['photoUrl'] ??
                              'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                        ),
                      ),
                      title: Text(friend['pseudo'] ?? 'Nom inconnu',
                          style: theme.bodyLarge),
                      subtitle: Text(
                        '${friend['surname'] ?? 'Nom inconnu'} ${friend['name'] ?? ''}',
                        style: theme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: theme.secondary),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Supprimer cet ami ?'),
                                content: Text(
                                  'Êtes-vous sûr de vouloir supprimer ${friend['pseudo']} ?',
                                  style: theme.bodyMedium
                                      .copyWith(color: theme.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('Annuler',
                                        style: theme.bodyMedium),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text('Supprimer',
                                        style: theme.bodyMedium),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            final friendUid = await fetchFriendUid(index);
                            if (friendUid != null) {
                              try {
                                final currentUserUid =
                                    FirebaseAuth.instance.currentUser!.uid;

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserUid)
                                    .update({
                                  'friends': FieldValue.arrayRemove([friendUid]),
                                });

                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(friendUid)
                                    .update({
                                  'friends': FieldValue.arrayRemove(
                                      [currentUserUid]),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${friend['pseudo']} supprimé.',
                                      style: theme.bodyMedium,
                                    ),
                                    backgroundColor: theme.secondary,
                                  ),
                                );

                                // Actualiser la liste après suppression
                                refreshFriends();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Erreur : $e',
                                      style: theme.bodyMedium,
                                    ),
                                    backgroundColor: theme.secondary,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPendingApprovalsSection(AppTheme theme) {
    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demande d\'amis', style: theme.titleLarge),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: pendingApprovalsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune demande en attente.',
                      style: theme.bodyMedium.copyWith(color: theme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final pendingList = snapshot.data!;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final pendingUser = pendingList[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          pendingUser['photoUrl'] ??
                              'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                        ),
                      ),
                      title: Text(pendingUser['pseudo'] ?? 'Nom inconnu',
                          style: theme.bodyLarge),
                      subtitle: Text(
                        '${pendingUser['surname'] ?? 'Nom inconnu'} ${pendingUser['name'] ?? ''}',
                        style: theme.bodyMedium,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                            try {
                              final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
                              final pendingUserUid = await fetchPendingApprovalUid(index);

                              if (currentUserUid == null || pendingUserUid == null) {
                                throw Exception("UID introuvable pour l'utilisateur ou la demande.");
                              }

                              // Ajouter aux amis
                              await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
                                'friends': FieldValue.arrayUnion([pendingUserUid]),
                                'pending_approval': FieldValue.arrayRemove([pendingUserUid]),
                              });

                              await FirebaseFirestore.instance.collection('users').doc(pendingUserUid).update({
                                'friends': FieldValue.arrayUnion([currentUserUid]),
                                'friend_requests': FieldValue.arrayRemove([currentUserUid]),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${pendingUser['pseudo']} ajouté comme ami.')),
                              );

                              // Rafraîchir les données
                              refreshFriends();
                              refreshPendingApprovals();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },

                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.secondary),
                            onPressed: () async {
                            try {
                              final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
                              final pendingUserUid = await fetchPendingApprovalUid(index);

                              if (currentUserUid == null || pendingUserUid == null) {
                                throw Exception("UID introuvable pour l'utilisateur ou la demande.");
                              }

                              // Supprimer la demande
                              await FirebaseFirestore.instance.collection('users').doc(currentUserUid).update({
                                'pending_approval': FieldValue.arrayRemove([pendingUserUid]),
                              });

                              await FirebaseFirestore.instance.collection('users').doc(pendingUserUid).update({
                                'friend_requests': FieldValue.arrayRemove([currentUserUid]),
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Demande refusée.')),
                              );

                              // Rafraîchir les données
                              refreshFriends();
                              refreshPendingApprovals();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
