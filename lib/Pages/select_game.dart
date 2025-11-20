import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final List<Map<String, String>> jeuxEnLocal = [
      {
        'name': 'Killer',
        'description': 'Un jeu d’assassin mystérieux.',
        'image':
            'https://img.icons8.com/?size=100&id=20802&format=png&color=000000',
        'route': '/killer',
      },
      {
        'name': 'Clicker',
        'description': 'Une compétition de clique.',
        'image':
            'https://img.icons8.com/?size=100&id=gjsnNuxwktgL&format=png&color=000000',
        'route': '/clicker_game',
      },
      {
        'name': 'Bizkit !',
        'description': 'Lancez les dés et suivez les règles amusantes !',
        'image':
            'https://img.icons8.com/?size=100&id=80024&format=png&color=000000',
        'route': '/dice_game',
      },
      {
        'name': 'Jeu des papiers',
        'description': 'Un jeu de papier mystérieux.',
        'image':
            'https://img.icons8.com/?size=100&id=22033&format=png&color=000000',
        'route': '/Pages/lobby_screen',
      },
      {
        'name': 'L\'horloge',
        'description': 'Parier sur votre chance.',
        'image':
            'https://img.icons8.com/?size=100&id=34&format=png&color=000000',
        'route': '/Pages/lobby_screen',
      },
      {
        'name': 'Test de réflexes',
        'description': 'Un jeu pour tester vos réflexes.',
        'image':
            'https://img.icons8.com/?size=100&id=61096&format=png&color=000000',
        'route': '/reflex_game',
      },
      {
        'name': 'Suit la ligne',
        'description': 'Un jeu de rapidité et de concentration.',
        'image':
            'https://img.icons8.com/?size=100&id=87064&format=png&color=000000',
        'route': '/follow_line',
      },
      {
        'name': 'Pyramide',
        'description':
            'Retourne la pyramide de cartes en commençant par la base.',
        'image':
            'https://img.icons8.com/?size=100&id=QJJ60v6ChwhS&format=png&color=000000',
        'route': '/pyramid',
      },
      {
        'name': 'Pyramide moderne',
        'description': 'Version carrousel pour retourner les cartes une à une.',
        'image':
            'https://img.icons8.com/?size=100&id=571&format=png&color=000000',
        'route': '/pyramid_modern',
      },
    ];

    final List<Map<String, String>> jeuxEnLigne = [
      {
        'name': 'Jeu du débat', // 🔹 Faux jeu pour tester
        'description': 'Jeu de bluff et de stratégie.',
        'image':
            'https://img.icons8.com/?size=100&id=rGBIEi57JpPS&format=png&color=000000',
        'route': '/online_lobby',
      },
    ];

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
        'image':
            'https://e7.pngegg.com/pngimages/993/804/png-clipart-gambling-playing-card-game-of-chance-computer-icons-others-miscellaneous-game.png',
        'route': '/cardDrawer',
      },
      {
        'name': 'Cartes pyramide',
        'description': '4 cartes pour jouer à la pyramide.',
        'image':
            'https://img.icons8.com/?size=100&id=QJJ60v6ChwhS&format=png&color=000000',
        'route': '/pyramid_card',
      },
      {
        'name': 'ShifuShot ?',
        'description': 'Envoyer une notif de shifushot',
        'image':
            'https://img.icons8.com/?size=100&id=LkjR8vZ077vb&format=png&color=000000',
        'route': '/shifushot_request',
      },
      {
        'name': 'Sonothèque',
        'description': 'banque de sons',
        'image':
            'https://img.icons8.com/?size=100&id=41562&format=png&color=000000',
        'route': '/select_sound',
      },
      {
        'name': 'Les 12 bars',
        'description': 'Prêt à relever le défi ?',
        'image':
            'https://img.icons8.com/?size=100&id=97404&format=png&color=000000',
        'route': '/twelve_bars',
      }
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.textPrimary,
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/homepage', (route) => false);
          },
        ),
        title: Text('Sélectionnez un jeu', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
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
            ...jeuxEnLocal.map(
                (game) => GameCard(game: game, theme: theme, context: context)),

            const SizedBox(height: 20),

            // 🔹 Jeux en Ligne (avec un faux jeu pour test)
            Text(
              "🌐 Jeux en Ligne",
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...jeuxEnLigne.map(
                (game) => GameCard(game: game, theme: theme, context: context)),

            const SizedBox(height: 20),

            // 🔹 Fonctionnalités
            Text(
              "⚙️ Fonctionnalités",
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...fonctionnalites.map((feature) =>
                GameCard(game: feature, theme: theme, context: context)),
          ],
        ),
      ),
    );
  }
}

// 🔹 Widget pour une carte de jeu
Widget GameCard(
    {required Map<String, String> game,
    required AppTheme theme,
    required BuildContext context}) {
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
