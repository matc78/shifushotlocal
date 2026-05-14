import 'package:flutter/material.dart';
import 'package:shifushotlocal/pages/auth/guest_prompt.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class _GameEntry {
  const _GameEntry({
    required this.name,
    required this.description,
    required this.emoji,
    required this.route,
    required this.gradient,
    this.requiresAccount = false,
  });

  final String name;
  final String description;
  final String emoji;
  final String route;
  final List<Color> gradient;
  final bool requiresAccount;
}

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({super.key});

  static const _g1 = [Color(0xFFFF3DAA), Color(0xFF9747FF)];
  static const _g2 = [Color(0xFF9747FF), Color(0xFF3D8BFF)];
  static const _g3 = [Color(0xFFFF8A3D), Color(0xFFFF3DAA)];
  static const _g4 = [Color(0xFFE7FF3F), Color(0xFFFF8A3D)];
  static const _g5 = [Color(0xFF3D8BFF), Color(0xFF3DFFD7)];

  static const _localGames = <_GameEntry>[
    _GameEntry(
      name: 'Killer',
      description: 'Le jeu d’assassin mystérieux',
      emoji: '🔪',
      route: '/killer',
      gradient: _g1,
    ),
    _GameEntry(
      name: 'Clicker',
      description: 'Compétition de clique brutale',
      emoji: '👆',
      route: '/clicker_game',
      gradient: _g2,
    ),
    _GameEntry(
      name: 'Bizkit !',
      description: 'Lance les dés, suis les règles',
      emoji: '🎲',
      route: '/dice_game',
      gradient: _g3,
    ),
    _GameEntry(
      name: 'Jeu des papiers',
      description: 'Un jeu de papier mystérieux',
      emoji: '📜',
      route: '/lobby_screen',
      gradient: _g4,
    ),
    _GameEntry(
      name: "L'horloge",
      description: 'Pariez sur votre chance',
      emoji: '⏰',
      route: '/lobby_screen',
      gradient: _g5,
    ),
    _GameEntry(
      name: 'Test de réflexes',
      description: 'Plus rapide que tes potes ?',
      emoji: '⚡',
      route: '/reflex_game',
      gradient: _g1,
    ),
    _GameEntry(
      name: 'Suit la ligne',
      description: 'Rapidité & concentration',
      emoji: '🎯',
      route: '/follow_line',
      gradient: _g2,
    ),
    _GameEntry(
      name: 'Pyramide',
      description: 'Retourne la pyramide par la base',
      emoji: '🃏',
      route: '/pyramid',
      gradient: _g3,
    ),
    _GameEntry(
      name: 'Pyramide moderne',
      description: 'Version carrousel des cartes',
      emoji: '🎴',
      route: '/pyramid_modern',
      gradient: _g4,
    ),
  ];

  static const _onlineGames = <_GameEntry>[
    _GameEntry(
      name: 'Jeu du débat',
      description: 'Bluff & stratégie',
      emoji: '🎙️',
      route: '/online_lobby',
      gradient: _g5,
      requiresAccount: true,
    ),
  ];

  static const _features = <_GameEntry>[
    _GameEntry(
      name: "Créateur d'équipes",
      description: 'Génère des équipes au hasard',
      emoji: '👥',
      route: '/teamGenerator',
      gradient: _g2,
    ),
    _GameEntry(
      name: 'Tireur de cartes',
      description: 'Tire des cartes (avec ou sans Joker)',
      emoji: '🎴',
      route: '/cardDrawer',
      gradient: _g1,
    ),
    _GameEntry(
      name: 'Cartes pyramide',
      description: '4 cartes pour la pyramide',
      emoji: '🔺',
      route: '/pyramid_card',
      gradient: _g3,
    ),
    _GameEntry(
      name: 'ShifuShot ?',
      description: 'Envoyer une notif de shifushot',
      emoji: '✊',
      route: '/shifushot_request',
      gradient: _g5,
      requiresAccount: true,
    ),
    _GameEntry(
      name: 'Sonothèque',
      description: 'La banque de sons',
      emoji: '🔊',
      route: '/select_sound',
      gradient: _g4,
    ),
    _GameEntry(
      name: 'Les 12 bars',
      description: 'Prêt à relever le défi ?',
      emoji: '🍻',
      route: '/twelve_bars',
      gradient: _g3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isGuest = GuestSession.instance.isGuest;

    return Scaffold(
      body: PartyBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: theme.textPrimary,
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/homepage',
                    (route) => false,
                  ),
                ),
                title: Text('Choisis ton jeu', style: theme.titleMedium),
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.list(
                  children: [
                    const _SectionTitle('🎮  En local'),
                    const SizedBox(height: 12),
                    _GameGrid(games: _localGames, isGuest: isGuest),
                    const SizedBox(height: 28),
                    const _SectionTitle('🌐  En ligne'),
                    const SizedBox(height: 12),
                    _GameGrid(games: _onlineGames, isGuest: isGuest),
                    const SizedBox(height: 28),
                    const _SectionTitle('⚙️  Outils & fun'),
                    const SizedBox(height: 12),
                    _GameGrid(games: _features, isGuest: isGuest),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Text(
      label,
      style: theme.titleLarge.copyWith(fontSize: 24, letterSpacing: 0.5),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.games, required this.isGuest});
  final List<_GameEntry> games;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: games.length,
      itemBuilder: (_, i) => _GameTile(game: games[i], isGuest: isGuest),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.isGuest});
  final _GameEntry game;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final locked = isGuest && game.requiresAccount;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () async {
        if (locked) {
          await promptToSignUp(
            context,
            reason:
                'Le mode en ligne nécessite un compte pour jouer avec tes potes.',
          );
          return;
        }
        if (!context.mounted) return;
        Navigator.pushNamed(context, game.route, arguments: game.name);
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: game.gradient,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: locked ? null : theme.cardShadow,
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text(
                    game.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleMedium.copyWith(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked ? 'Compte requis' : game.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (locked)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
