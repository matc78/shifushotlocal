// ... imports inchangés
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final friendsUids = List<String>.from(userData['friends'] ?? []);
          final pendingUids = List<String>.from(userData['pending_approval'] ?? []);

          return Padding(
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  buildUserListSection("Liste amis", friendsUids, theme, isFriend: true),
                  const SizedBox(height: 20),
                  buildUserListSection("Demandes d'amis", pendingUids, theme, isFriend: false),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildUserListSection(String title, List<String> uids, AppTheme theme, {required bool isFriend}) {
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
            Text(title, style: theme.titleLarge),
            const SizedBox(height: 10),
            if (uids.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      isFriend
                          ? 'Autant d\'amis que de "\u00e7" dans surf ?'
                          : 'Aucune demande ? Brice est fier de toi !',
                      style: theme.bodyMedium.copyWith(color: theme.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      'https://mathsamoi.com/wp-content/uploads/2019/10/061-image-entrc3a9e-1.png?w=640',
                      width: 200,
                      height: 200,
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: uids.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final uid = uids[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }

                      final user = snapshot.data!.data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            user['photoUrl'] ??
                                'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg',
                          ),
                        ),
                        title: Text(user['pseudo'] ?? '', style: theme.bodyLarge),
                        subtitle: Text(
                          '${user['surname'] ?? ''} ${user['name'] ?? ''}',
                          style: theme.bodyMedium,
                        ),
                        trailing: isFriend
                            ? IconButton(
                                icon: Icon(Icons.delete, color: theme.secondary),
                                onPressed: () async {
                                  final currentUid = FirebaseAuth.instance.currentUser!.uid;

                                  await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
                                    'friends': FieldValue.arrayRemove([uid]),
                                  });

                                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    'friends': FieldValue.arrayRemove([currentUid]),
                                  });
                                },
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () async {
                                      final currentUid = FirebaseAuth.instance.currentUser!.uid;

                                      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
                                        'friends': FieldValue.arrayUnion([uid]),
                                        'pending_approval': FieldValue.arrayRemove([uid]),
                                      });

                                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                        'friends': FieldValue.arrayUnion([currentUid]),
                                        'friend_requests': FieldValue.arrayRemove([currentUid]),
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: theme.secondary),
                                    onPressed: () async {
                                      final currentUid = FirebaseAuth.instance.currentUser!.uid;

                                      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
                                        'pending_approval': FieldValue.arrayRemove([uid]),
                                      });

                                      await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                        'friend_requests': FieldValue.arrayRemove([currentUid]),
                                      });
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