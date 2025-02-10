import 'package:flutter/material.dart';
import 'package:shifushotlocal/app_theme.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({Key? key}) : super(key: key);

  @override
  _PartyScreenState createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  final List<String> moods = ['Hardcore', 'Chill', 'Découverte'];
  String selectedMood = 'Chill';
  final List<String> games = ['/paper_game', '/jeu1', '/dice_game', '/clock-game'];

  void startParty() {
    games.shuffle(); // Shuffle the games randomly
    Navigator.pushNamed(
      context,
      '/Pages/lobby_screen', // Navigate to the Lobby Screen
      arguments: {
        'mode': 'Soirée',
        'selectedGames': games, // Pass the shuffled list of games
        'mood': selectedMood,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Créer une soirée', style: theme.titleMedium),
        backgroundColor: theme.background,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedMood,
              decoration: InputDecoration(
                labelText: 'Choisissez le mood de la soirée',
                labelStyle: TextStyle(color: theme.textPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
              items: moods
                  .map((mood) => DropdownMenuItem(
                        value: mood,
                        child: Text(mood, style: theme.bodyLarge),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMood = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startParty,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text("Démarrer la soirée", style: theme.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
