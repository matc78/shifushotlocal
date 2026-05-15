import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  static const _defaultAvatar =
      'https://img.freepik.com/vecteurs-premium/vecteur-conception-logo-mascotte-sanglier_497517-52.jpg';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _acceptRequest(String uid) async {
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(_uid).update({
      'friends': FieldValue.arrayUnion([uid]),
      'pending_approval': FieldValue.arrayRemove([uid]),
    });
    await users.doc(uid).update({
      'friends': FieldValue.arrayUnion([_uid]),
      'friend_requests': FieldValue.arrayRemove([_uid]),
    });
  }

  Future<void> _rejectRequest(String uid) async {
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(_uid).update({
      'pending_approval': FieldValue.arrayRemove([uid]),
    });
    await users.doc(uid).update({
      'friend_requests': FieldValue.arrayRemove([_uid]),
    });
  }

  Future<void> _removeFriend(String uid) async {
    final users = FirebaseFirestore.instance.collection('users');
    await users.doc(_uid).update({
      'friends': FieldValue.arrayRemove([uid]),
    });
    await users.doc(uid).update({
      'friends': FieldValue.arrayRemove([_uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Tes potes',
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const _LoadingList();
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final friends = List<String>.from(data['friends'] ?? []);
          final pending = List<String>.from(data['pending_approval'] ?? []);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientButton(
                  label: 'Ajouter un pote',
                  icon: Icons.person_add_alt_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.addFriend),
                ),
                const SizedBox(height: 28),
                _SectionTitle(label: 'AMIS', count: friends.length),
                const SizedBox(height: 12),
                _UserList(
                  uids: friends,
                  emptyTitle: 'Aucun ami pour l\'instant',
                  emptySubtitle:
                      'Ajoute des potes pour lancer des parties ensemble.',
                  trailingBuilder: (uid) => IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: AppTheme.of(context).textMuted),
                    onPressed: () => _removeFriend(uid),
                  ),
                ),
                const SizedBox(height: 28),
                _SectionTitle(label: 'DEMANDES', count: pending.length),
                const SizedBox(height: 12),
                _UserList(
                  uids: pending,
                  emptyTitle: 'Aucune demande en attente',
                  emptySubtitle:
                      'On t\'enverra une notif si quelqu\'un t\'ajoute.',
                  trailingBuilder: (uid) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_rounded,
                            color: AppTheme.of(context).primary),
                        onPressed: () => _acceptRequest(uid),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: AppTheme.of(context).textMuted),
                        onPressed: () => _rejectRequest(uid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: SkeletonListTile(),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: theme.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: theme.overline.copyWith(
              color: theme.textPrimary,
              fontSize: 13,
              letterSpacing: 2,
            )),
        const SizedBox(width: 8),
        Text('$count',
            style: theme.overline.copyWith(
              color: theme.textMuted,
              fontSize: 13,
              letterSpacing: 1,
            )),
      ],
    );
  }
}

class _UserList extends StatelessWidget {
  const _UserList({
    required this.uids,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.trailingBuilder,
  });

  final List<String> uids;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(String uid) trailingBuilder;

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: uids.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) =>
          _UserTile(uid: uids[i], trailing: trailingBuilder(uids[i])),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.uid, required this.trailing});

  final String uid;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SkeletonListTile();
        if (!snapshot.data!.exists) return const SizedBox.shrink();
        final user = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl =
            (user['photoUrl'] as String?)?.trim().isNotEmpty == true
                ? user['photoUrl'] as String
                : _FriendsPageState._defaultAvatar;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: CachedNetworkImageProvider(photoUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user['pseudo'] ?? '',
                      style: theme.bodyLarge.copyWith(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user['surname'] ?? ''} ${user['name'] ?? ''}'.trim(),
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        );
      },
    );
  }
}
