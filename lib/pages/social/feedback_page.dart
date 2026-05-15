import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _titleController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : null,
      ));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final feedback = _feedbackController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (title.isEmpty || feedback.isEmpty) {
      _snack('Remplis tous les champs.', error: true);
      return;
    }
    if (uid == null) {
      _snack('Utilisateur non authentifié.', error: true);
      return;
    }

    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'title': title,
        'feedback': feedback,
        'uid': uid,
        'response': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _titleController.clear();
      _feedbackController.clear();
      _snack('Merci pour ton retour !');
    } catch (e) {
      _snack('Erreur, réessaie.', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return AppShell(
      title: 'Feedback',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'On lit tout. Promis.',
              style: theme.titleLarge.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Bug, suggestion, coup de gueule — balance.',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              maxLength: 20,
              style: theme.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Titre',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              style: theme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Ton message…'),
            ),
            const SizedBox(height: 16),
            GradientButton(
              label: _sending ? 'Envoi…' : 'Envoyer',
              icon: Icons.send_rounded,
              onPressed: _sending ? null : _submit,
            ),
            const SizedBox(height: 32),
            Row(
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
                Text('MES RETOURS',
                    style: theme.overline.copyWith(
                      color: theme.textPrimary,
                      fontSize: 13,
                      letterSpacing: 2,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: uid == null
                  ? const EmptyState(
                      icon: Icons.account_circle_outlined,
                      title: 'Compte requis',
                      subtitle: 'Connecte-toi pour suivre tes feedbacks.',
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('feedback')
                          .where('uid', isEqualTo: uid)
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ListView.separated(
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, __) => const SkeletonListTile(),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Aucun feedback envoyé',
                            subtitle: "Hésite SURTOUT pas hein.",
                          );
                        }
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _FeedbackRow(doc: docs[i], theme: theme),
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

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.doc, required this.theme});
  final QueryDocumentSnapshot doc;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    final title = doc['title'] as String;
    final Timestamp? ts = doc['timestamp'] as Timestamp?;
    final formatted = ts != null
        ? DateFormat('d/M/yy HH:mm').format(ts.toDate())
        : 'Date inconnue';

    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => FeedbackDetailPage(feedback: doc)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: theme.bodyLarge.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 2),
                    Text(formatted, style: theme.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                icon:
                    Icon(Icons.delete_outline_rounded, color: theme.textMuted),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce feedback ?'),
        content: const Text('Tu ne pourras pas le récupérer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(doc.id)
          .delete();
      messenger.showSnackBar(const SnackBar(
        content: Text('Feedback supprimé.'),
        backgroundColor: Colors.green,
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Erreur lors de la suppression.'),
        backgroundColor: Colors.red,
      ));
    }
  }
}

class FeedbackDetailPage extends StatelessWidget {
  const FeedbackDetailPage({super.key, required this.feedback});
  final QueryDocumentSnapshot feedback;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final title = feedback['title'] as String;
    final body = feedback['feedback'] as String;
    final response = feedback['response'] as String;

    return AppShell(
      title: 'Détail',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.titleLarge.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            SectionCard(
              child: Text(body,
                  style: theme.bodyLarge.copyWith(color: theme.textPrimary)),
            ),
            const Spacer(),
            SectionCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    response.isEmpty
                        ? Icons.hourglass_top_rounded
                        : Icons.mail_rounded,
                    color: theme.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      response.isEmpty
                          ? "En attente du retour de l'équipe Shifushot."
                          : response,
                      style: theme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
