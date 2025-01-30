import 'package:flutter/material.dart';
import 'app_theme.dart';

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final List<Map<String, String>> games = [
      {
        'name': 'Créateur d\'équipes',
        'description': 'Générer des équipes de manière aléatoire.',
        'image': 'https://img.icons8.com/fluency/96/group.png',
        'route': '/teamGenerator',
      },
      {
        'name': 'Devinez qui',
        'description': 'Un jeu pour mieux se connaître.',
        'image': 'https://img.icons8.com/fluency/96/question-mark.png',
        'route': '/guessWho',
      },
      {
        'name': 'Blind Test',
        'description': 'Testez vos connaissances musicales.',
        'image': 'https://img.icons8.com/fluency/96/microphone.png',
        'route': '/blindTest',
      },
      {
        'name': 'Killer',
        'description': 'Un jeu d’assassin mystérieux.',
        'image': 'https://img.icons8.com/?size=100&id=20802&format=png&color=000000',
        'route': '/killer',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionnez un jeu', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(game['image']!),
                  radius: 30,
                ),
                title: Text(
                  game['name']!,
                  style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(game['description']!, style: theme.bodyMedium),
                trailing: Icon(Icons.arrow_forward, color: theme.textSecondary),
                onTap: () {
                  Navigator.pushNamed(context, game['route']!);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
