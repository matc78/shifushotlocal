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

  void addPlayer() {
    if (_playerController.text.isNotEmpty) {
      setState(() {
        players.add(_playerController.text.trim());
        _playerController.clear();
      });
    }
  }

  void startGame() {
    if (players.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/jeu1', // Changez cette route si nécessaire
        arguments: players,
      );
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
          "Lobby du jeu",
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary), // Couleur des icônes
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
                  return ListTile(
                    title: Text(
                      players[index],
                      style: theme.bodyLarge,
                    ),
                    trailing: IconButton(
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
