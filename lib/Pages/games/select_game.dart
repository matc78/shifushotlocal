import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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
        'name': 'Killer',
        'description': 'Un jeu d’assassin mystérieux.',
        'image': 'https://img.icons8.com/?size=100&id=20802&format=png&color=000000',
        'route': '/killer',
      },
      {
        'name': 'Clicker',
        'description': 'Une compétition de clique.',
        'image': 'https://img.icons8.com/?size=100&id=gjsnNuxwktgL&format=png&color=000000',
        'route': '/Pages/lobby_screen',
      },
      {
        'name': 'Bizkit !',
        'description': 'Lancez les dés et suivez les règles amusantes !',
        'image': 'https://img.icons8.com/?size=100&id=80024&format=png&color=000000',
        'route': '/dice_game',
      },
      {
        'name': 'Jeu des papiers',
        'description': 'Un jeu de papier mystérieux.',
        'image': 'https://img.icons8.com/?size=100&id=22033&format=png&color=000000',
        'route': '/Pages/lobby_screen',
      },
      {
        'name': 'L\'horloge',
        'description': 'Parier sur votre chance.',
        'image': 'https://img.icons8.com/?size=100&id=34&format=png&color=000000',
        'route': '/Pages/lobby_screen',
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
                  // Passer le nom du jeu en argument
                  Navigator.pushNamed(
                    context,
                    game['route']!,
                    arguments: game['name'], 
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
