import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';

class KillerPage extends StatefulWidget {
  const KillerPage({super.key});

  @override
  State<KillerPage> createState() => _KillerPageState();
}

class _KillerPageState extends State<KillerPage> {
  final List<String> players = [];
  final TextEditingController playerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  Future<void> _fetchUserSurname() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      // Récupérer le document utilisateur dans Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Récupérer le champ 'surname'
        final surname = userDoc.data()?['surname'] ?? "Moi";

        setState(() {
          players.add(surname); // Ajouter le surname à la liste des joueurs
        });
      } else {
        // Si le document n'existe pas, utilisez une valeur par défaut
        setState(() {
          players.add("Moi");
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération du surname : $e');
      setState(() {
        players.add("Moi");
      });
    }
  }
}

  void startGame() {
    if (players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins 3 joueurs.')),
      );
      return;
    }

    Navigator.pushNamed(context, '/killerActions', arguments: players);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Killer', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: playerController,
                    decoration: InputDecoration(
                      labelText: 'Ajouter un joueur',
                      labelStyle: theme.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primary),
                      ),
                    ),
                    style: theme.bodyLarge,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (playerController.text.isNotEmpty) {
                      setState(() {
                        players.add(playerController.text.trim());
                        playerController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Ajouter', style: theme.buttonText),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final isCurrentUser = index == 0; // L'utilisateur connecté est toujours le premier

                  return ListTile(
                    title: Text(players[index], style: theme.bodyLarge),
                    trailing: isCurrentUser
                        ? null // Pas de bouton de suppression pour l'utilisateur connecté
                        : IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                players.removeAt(index);
                              });
                            },
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Commencer le jeu', style: theme.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
