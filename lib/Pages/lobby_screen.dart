import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/app_theme.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final List<String> players = [];
  final TextEditingController _playerController = TextEditingController();
  late String mode; // Mode de jeu: "Jeu" ou "Soirée"
  late String gameName; // Nom du jeu ou "Soirée"
  List<String> remainingGames = []; // Liste des jeux pour une soirée ou mode jeu

  // Table de correspondance entre les noms des jeux et leurs routes
  final Map<String, String> gameRoutes = {
    'Clicker': '/jeu1',
    'Bizkit !': '/dice_game',
    'Jeu des papiers': '/paper_game',
  };

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    print('Arguments reçus : $args');

    if (args is String) {
      // Mode "Jeu"
      mode = 'Jeu';
      gameName = args;
      final route = gameRoutes[gameName]; // Obtenir la route correspondante
      if (route != null) {
        remainingGames = [route, '/homepage']; // Ajouter la route du jeu et la page d'accueil
      } else {
        remainingGames = ['/homepage']; // Par défaut, rediriger vers l'accueil
        print('Aucune route trouvée pour $gameName');
      }
    } else if (args is Map<String, dynamic>) {
      // Mode "Soirée"
      mode = args['mode'] ?? 'Soirée';
      gameName = args['gameName'] ?? 'Soirée';
      remainingGames = args['remainingGames'] ?? [];

      // Si aucune liste de jeux n'est fournie, initialisez avec une liste aléatoire
      if (remainingGames.isEmpty) {
        final allGames = gameRoutes.values.toList();
        allGames.shuffle();
        remainingGames = allGames; // Liste aléatoire des jeux
      }
    } else {
      // Valeurs par défaut
      mode = 'Jeu';
      gameName = 'Jeu';
      remainingGames = ['/homepage'];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  /// Récupérer le nom de l'utilisateur connecté et l'ajouter en premier dans la liste
  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final surname = userDoc.data()?['surname'] ?? "Moi";
          if (mounted) {
            setState(() {
              players.add(surname); // Ajouter le nom de l'utilisateur
            });
          }
        } else {
          if (mounted) {
            setState(() {
              players.add("Moi");
            });
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération du surname : $e');
        if (mounted) {
          setState(() {
            players.add("Moi");
          });
        }
      }
    }
  }

  /// Ajouter un joueur (hors utilisateur connecté)
  void addPlayer() {
    if (_playerController.text.isNotEmpty) {
      setState(() {
        players.add(_playerController.text.trim());
        _playerController.clear();
      });
    }
  }

  /// Commencer le jeu ou une soirée
  void startGame() {
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins un joueur !")),
      );
      return;
    }

    if (remainingGames.isNotEmpty) {
      Navigator.pushNamed(
        context,
        remainingGames.first,
        arguments: {
          'players': players,
          'remainingGames': remainingGames.sublist(1),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          mode == 'Soirée' ? "Lobby - Soirée" : "Lobby - $gameName",
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (mode == 'Soirée') // Afficher les jeux sélectionnés dans le mode soirée
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  children: [
                    Text(
                      "Jeux sélectionnés :",
                      style: theme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: remainingGames
                          .map((game) => Chip(
                                label: Text(
                                  game,
                                  style: theme.bodyMedium,
                                ),
                                backgroundColor: theme.primary.withOpacity(0.1),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _playerController,
              decoration: InputDecoration(
                labelText: "Nom du joueur",
                labelStyle: TextStyle(color: theme.textPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
              style: TextStyle(color: theme.textPrimary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Ajouter un joueur",
                style: theme.buttonText,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final bool isCurrentUser = index == 0; // L'utilisateur connecté est toujours le premier

                  return ListTile(
                    title: Text(
                      players[index],
                      style: theme.bodyLarge,
                    ),
                    trailing: isCurrentUser
                        ? null // Pas de suppression pour l'utilisateur connecté
                        : IconButton(
                            icon: Icon(Icons.delete, color: theme.secondary),
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
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                mode == 'Soirée' ? "Commencer la soirée" : "Commencer le jeu",
                style: theme.titleMedium.copyWith(
                  color: Colors.white,
                  fontSize: 24.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
