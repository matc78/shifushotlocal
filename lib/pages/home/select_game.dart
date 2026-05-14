import 'package:flutter/material.dart';
import 'package:shifushotlocal/pages/auth/guest_prompt.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class _GameEntry {
  const _GameEntry({
    required this.name,
    required this.description,
    required this.image,
    required this.route,
    this.requiresAccount = false,
  });

  final String name;
  final String description;
  final String image;
  final String route;
  final bool requiresAccount;
}

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({super.key});

  static const _localGames = <_GameEntry>[
    _GameEntry(
      name: 'Killer',
      description: 'Un jeu d’assassin mystérieux.',
      image: 'https://img.icons8.com/?size=100&id=20802&format=png&color=000000',
      route: '/killer',
    ),
    _GameEntry(
      name: 'Clicker',
      description: 'Une compétition de clique.',
      image: 'https://img.icons8.com/?size=100&id=gjsnNuxwktgL&format=png&color=000000',
      route: '/clicker_game',
    ),
    _GameEntry(
      name: 'Bizkit !',
      description: 'Lancez les dés et suivez les règles amusantes !',
      image: 'https://img.icons8.com/?size=100&id=80024&format=png&color=000000',
      route: '/dice_game',
    ),
    _GameEntry(
      name: 'Jeu des papiers',
      description: 'Un jeu de papier mystérieux.',
      image: 'https://img.icons8.com/?size=100&id=22033&format=png&color=000000',
      route: '/lobby_screen',
    ),
    _GameEntry(
      name: "L'horloge",
      description: 'Parier sur votre chance.',
      image: 'https://img.icons8.com/?size=100&id=34&format=png&color=000000',
      route: '/lobby_screen',
    ),
    _GameEntry(
      name: 'Test de réflexes',
      description: 'Un jeu pour tester vos réflexes.',
      image: 'https://img.icons8.com/?size=100&id=61096&format=png&color=000000',
      route: '/reflex_game',
    ),
    _GameEntry(
      name: 'Suit la ligne',
      description: 'Un jeu de rapidité et de concentration.',
      image: 'https://img.icons8.com/?size=100&id=87064&format=png&color=000000',
      route: '/follow_line',
    ),
    _GameEntry(
      name: 'Pyramide',
      description: 'Retourne la pyramide de cartes en commençant par la base.',
      image: 'https://img.icons8.com/?size=100&id=QJJ60v6ChwhS&format=png&color=000000',
      route: '/pyramid',
    ),
    _GameEntry(
      name: 'Pyramide moderne',
      description: 'Version carrousel pour retourner les cartes une à une.',
      image: 'https://img.icons8.com/?size=100&id=571&format=png&color=000000',
      route: '/pyramid_modern',
    ),
  ];

  static const _onlineGames = <_GameEntry>[
    _GameEntry(
      name: 'Jeu du débat',
      description: 'Jeu de bluff et de stratégie.',
      image: 'https://img.icons8.com/?size=100&id=rGBIEi57JpPS&format=png&color=000000',
      route: '/online_lobby',
      requiresAccount: true,
    ),
  ];

  static const _features = <_GameEntry>[
    _GameEntry(
      name: "Créateur d'équipes",
      description: 'Générer des équipes de manière aléatoire.',
      image: 'https://img.icons8.com/fluency/96/group.png',
      route: '/teamGenerator',
    ),
    _GameEntry(
      name: 'Tireur de cartes',
      description: 'Tirer des cartes aléatoires avec ou sans Joker.',
      image:
          'https://e7.pngegg.com/pngimages/993/804/png-clipart-gambling-playing-card-game-of-chance-computer-icons-others-miscellaneous-game.png',
      route: '/cardDrawer',
    ),
    _GameEntry(
      name: 'Cartes pyramide',
      description: '4 cartes pour jouer à la pyramide.',
      image: 'https://img.icons8.com/?size=100&id=QJJ60v6ChwhS&format=png&color=000000',
      route: '/pyramid_card',
    ),
    _GameEntry(
      name: 'ShifuShot ?',
      description: 'Envoyer une notif de shifushot',
      image: 'https://img.icons8.com/?size=100&id=LkjR8vZ077vb&format=png&color=000000',
      route: '/shifushot_request',
      requiresAccount: true,
    ),
    _GameEntry(
      name: 'Sonothèque',
      description: 'banque de sons',
      image: 'https://img.icons8.com/?size=100&id=41562&format=png&color=000000',
      route: '/select_sound',
    ),
    _GameEntry(
      name: 'Les 12 bars',
      description: 'Prêt à relever le défi ?',
      image: 'https://img.icons8.com/?size=100&id=97404&format=png&color=000000',
      route: '/twelve_bars',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isGuest = GuestSession.instance.isGuest;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.textPrimary,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/homepage',
            (route) => false,
          ),
        ),
        title: Text('Sélectionnez un jeu', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle('🎮 Jeux en Local', theme),
            ..._localGames.map((g) => _GameCard(game: g, isGuest: isGuest)),
            const SizedBox(height: 20),
            _SectionTitle('🌐 Jeux en Ligne', theme),
            ..._onlineGames.map((g) => _GameCard(game: g, isGuest: isGuest)),
            const SizedBox(height: 20),
            _SectionTitle('⚙️ Fonctionnalités', theme),
            ..._features.map((g) => _GameCard(game: g, isGuest: isGuest)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.theme);
  final String label;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.isGuest});

  final _GameEntry game;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locked = isGuest && game.requiresAccount;
    return Card(
      elevation: locked ? 1 : 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: CircleAvatar(
            backgroundImage: NetworkImage(game.image),
            radius: 30,
          ),
        ),
        title: Text(
          game.name,
          style: theme.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: locked ? theme.textSecondary : null,
          ),
        ),
        subtitle: Text(
          locked ? 'Compte requis' : game.description,
          style: theme.bodyMedium,
        ),
        trailing: Icon(
          locked ? Icons.lock_outline : Icons.arrow_forward,
          color: theme.textSecondary,
        ),
        onTap: () async {
          if (locked) {
            await promptToSignUp(
              context,
              reason: 'Le mode en ligne nécessite un compte pour jouer avec tes amis.',
            );
            return;
          }
          Navigator.pushNamed(context, game.route, arguments: game.name);
        },
      ),
    );
  }
}
