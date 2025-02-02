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
  late String gameName = 'Jeu'; // Le nom du jeu sélectionné

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {
      gameName = ModalRoute.of(context)?.settings.arguments as String? ?? 'Jeu';
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  /// **Récupérer le nom de l'utilisateur connecté et l'ajouter en premier dans la liste**
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

  /// **Ajouter un joueur (hors utilisateur connecté)**
  void addPlayer() {
    if (_playerController.text.isNotEmpty) {
      setState(() {
        players.add(_playerController.text.trim());
        _playerController.clear();
      });
    }
  }

  /// **Lancer le jeu avec la bonne route**
  void startGame() {
    if (players.isNotEmpty) {
      String route;
      switch (gameName) {
        case 'Bizkit !':
          route = '/dice_game';
          break;
        case 'Jeu des papiers':
          route = '/paper_game';
          break;
        case 'Clicker':
          route = '/jeu1';
          break;
        default:
          route = '/';
      }

      Navigator.pushNamed(context, route, arguments: players);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez ajouter au moins un joueur !")),
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
          "Lobby - $gameName",
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
                "Commencer le jeu",
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
