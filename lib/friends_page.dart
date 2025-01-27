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

  @override
  void initState() {
    super.initState();
    friendsFuture = fetchFriends();
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

  void refreshFriends() {
    setState(() {
      friendsFuture = fetchFriends();
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
                      subtitle: Text(friend['email'] ?? 'Email inconnu',
                          style: theme.bodyMedium),
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
            Center(
              child: Text(
                'Aucune demande en attente.',
                style: theme.bodyMedium.copyWith(color: theme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
