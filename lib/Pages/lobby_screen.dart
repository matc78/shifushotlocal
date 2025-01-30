import 'package:flutter/material.dart';
import 'package:shifushotlocal/app_theme.dart'; // Import your AppTheme
import 'package:shifushotlocal/Pages/jeu1.dart';

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
        players.add(_playerController.text);
        _playerController.clear();
      });
    }
  }

  void startGame() {
    if (players.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Jeu1(players: players),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one player!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context); // Use AppTheme

    return Scaffold(
      backgroundColor: theme.background, // Set background color
      appBar: AppBar(
        title: const Text("Game Lobby"),
        backgroundColor: theme.primary, // Set app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _playerController,
              decoration: InputDecoration(
                labelText: "Enter Player Name",
                labelStyle: TextStyle(color: theme.textPrimary), // Set text color
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.primary), // Set border color
                ),
              ),
              style: TextStyle(color: theme.textPrimary), // Set input text color
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addPlayer,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary, // Set button color
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
              child: Text(
                "Add Player",
                style: theme.titleMedium.copyWith(color: Colors.white), // Set text color
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
                      style: TextStyle(color: theme.textPrimary), // Set text color
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary, // Set button color
                padding: const EdgeInsets.symmetric(vertical: 18.0),
                minimumSize: const Size(double.infinity, 60),
              ),
              child: Text(
                "Start Game",
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