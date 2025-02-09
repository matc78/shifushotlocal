import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final TextEditingController feedbackController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Feedback',
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
        backgroundColor: theme.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nous apprécions vos retours !',
                style: theme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Veuillez écrire un titre et vos remarques ci-dessous :',
                style: theme.bodyMedium,
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: titleController,
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: 'Titre (max 20 caractères)',
                  hintStyle: theme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: feedbackController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Écrivez ici...',
                  hintStyle: theme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  final String title = titleController.text.trim();
                  final String feedback = feedbackController.text.trim();
                  final String? uid = FirebaseAuth.instance.currentUser?.uid;

                  if (title.isEmpty || feedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Veuillez remplir tous les champs.',
                          style: theme.bodyMedium.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Utilisateur non authentifié.',
                          style: theme.bodyMedium.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance.collection('feedback').add({
                      'title': title,
                      'feedback': feedback,
                      'uid': uid,
                      'response': '', // Par défaut, aucun retour de l'équipe
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Merci pour votre retour !',
                          style: theme.bodyMedium.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    titleController.clear();
                    feedbackController.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de l\'envoi du feedback. Veuillez réessayer.',
                          style: theme.bodyMedium.copyWith(color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Text(
                  'Envoyer',
                  style: theme.titleMedium.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 35),
              Text(
                'Vos retours :',
                style: theme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                height: 300, // Limite la hauteur de la liste
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('feedback')
                      .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final feedbackDocs = snapshot.data!.docs;

                    if (feedbackDocs.isEmpty) {
                      return Center(
                        child: Text(
                          'Hésite SURTOUT pas hein',
                          style: theme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: feedbackDocs.length,
                      itemBuilder: (context, index) {
                        final feedbackData = feedbackDocs[index];
                        final String title = feedbackData['title'];
                        final String feedbackId = feedbackData.id; // ID du document Firestore
                        final Timestamp? timestamp = feedbackData['timestamp'];

                        // Conversion du timestamp en format d/m/yy h:m
                        final String formattedDate = timestamp != null
                            ? DateFormat('d/M/yy HH:mm').format(timestamp.toDate())
                            : 'Date inconnue';

                        return Card(
                          elevation: 3.0, // Ombre sous la carte
                          margin: const EdgeInsets.symmetric(vertical: 8.0), // Espacement vertical
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  title,
                                  style: theme.bodyMedium,
                                ),
                                Text(
                                  formattedDate,
                                  style: theme.bodyMedium.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);

                                // Affiche une boîte de confirmation avant la suppression
                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Supprimer ce feedback'),
                                    content: const Text(
                                        'Êtes-vous sûr de vouloir supprimer ce feedback ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Supprimer'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('feedback')
                                        .doc(feedbackId)
                                        .delete();

                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Feedback supprimé avec succès.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Erreur lors de la suppression du feedback.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FeedbackDetailPage(feedback: feedbackData),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FeedbackDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot feedback;

  const FeedbackDetailPage({Key? key, required this.feedback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final String title = feedback['title'];
    final String feedbackText = feedback['feedback'];
    final String response = feedback['response'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détail du Feedback',
          style: theme.titleMedium.copyWith(color: theme.textPrimary),
        ),
        backgroundColor: theme.background,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            Text(
              feedbackText,
              style: theme.bodyMedium,
            ),
            const Spacer(),
            Text(
              response.isEmpty
                  ? 'En attente du retour de l\'équipe Shifushot.'
                  : 'Retour de l\'équipe : $response',
              style: theme.bodyMedium.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
