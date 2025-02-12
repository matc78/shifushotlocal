import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final List<Map<String, String>> jeuxEnLocal = [
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

    // ignore: unused_local_variable
    final List<Map<String, String>> jeuxEnLigne = []; // Pour le moment, vide

    final List<Map<String, String>> fonctionnalites = [
      {
        'name': 'Créateur d\'équipes',
        'description': 'Générer des équipes de manière aléatoire.',
        'image': 'https://img.icons8.com/fluency/96/group.png',
        'route': '/teamGenerator',
      },
      {
        'name': 'Tireur de cartes',
        'description': 'Tirer des cartes aléatoires avec ou sans Joker.',
        'image': 'https://img.icons8.com/?size=100&id=16427&format=png&color=000000',
        'route': '/cardDrawer', // Assurez-vous que cette route est bien enregistrée dans `main.dart`
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
      body: SingleChildScrollView(  // Permet à toute la page d'être scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Jeux en Local
            Text(
              "🎮 Jeux en Local",
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...jeuxEnLocal.map((game) => GameCard(game: game, theme: theme, context: context)).toList(),

            const SizedBox(height: 20),

            // 🔹 Jeux en Ligne (Prochainement)
            Text(
              "🌐 Jeux en Ligne",
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "🚀 Prochainement",
                style: theme.bodyLarge.copyWith(color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Fonctionnalités
            Text(
              "⚙️ Fonctionnalités",
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...fonctionnalites.map((feature) => GameCard(game: feature, theme: theme, context: context)).toList(),
          ],
        ),
      ),
    );
  }
}

// 🔹 Widget pour une carte de jeu
Widget GameCard({required Map<String, String> game, required AppTheme theme, required BuildContext context}) {
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
        Navigator.pushNamed(
          context,
          game['route']!,
          arguments: game['name'], 
        );
      },
    ),
  );
}
