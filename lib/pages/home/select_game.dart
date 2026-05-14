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
    this.requiresAccount = false,
  });

  final String name;
  final String description;
  final String emoji;
  final String route;
  final bool requiresAccount;
}

class SelectGamePage extends StatelessWidget {
  const SelectGamePage({super.key});

  static const _localGames = <_GameEntry>[
    _GameEntry(name: 'Killer', description: 'Assassin mystérieux', emoji: '🔪', route: '/killer'),
    _GameEntry(name: 'Clicker', description: 'Compétition de clique', emoji: '👆', route: '/clicker_game'),
    _GameEntry(name: 'Bizkit !', description: 'Lance les dés', emoji: '🎲', route: '/dice_game'),
    _GameEntry(name: 'Jeu des papiers', description: 'Devine les phrases', emoji: '📜', route: '/lobby_screen'),
    _GameEntry(name: "L'horloge", description: 'Mise sur la chance', emoji: '⏰', route: '/lobby_screen'),
    _GameEntry(name: 'Réflexes', description: 'Le plus rapide gagne', emoji: '⚡', route: '/reflex_game'),
    _GameEntry(name: 'Suis la ligne', description: 'Précision & vitesse', emoji: '🎯', route: '/follow_line'),
    _GameEntry(name: 'Pyramide', description: 'Retourne par la base', emoji: '🃏', route: '/pyramid'),
    _GameEntry(name: 'Pyramide moderne', description: 'Carrousel de cartes', emoji: '🎴', route: '/pyramid_modern'),
  ];

  static const _onlineGames = <_GameEntry>[
    _GameEntry(name: 'Jeu du débat', description: 'Bluff & stratégie', emoji: '🎙️', route: '/online_lobby', requiresAccount: true),
  ];

  static const _features = <_GameEntry>[
    _GameEntry(name: "Créateur d'équipes", description: 'Équipes aléatoires', emoji: '👥', route: '/teamGenerator'),
    _GameEntry(name: 'Tireur de cartes', description: 'Cartes au hasard', emoji: '🎴', route: '/cardDrawer'),
    _GameEntry(name: 'Cartes pyramide', description: '4 cartes magiques', emoji: '🔺', route: '/pyramid_card'),
    _GameEntry(name: 'ShifuShot ?', description: 'Notif à tes amis', emoji: '✊', route: '/shifushot_request', requiresAccount: true),
    _GameEntry(name: 'Sonothèque', description: 'Banque de sons', emoji: '🔊', route: '/select_sound'),
    _GameEntry(name: 'Les 12 bars', description: 'Relèves le défi', emoji: '🍻', route: '/twelve_bars'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isGuest = GuestSession.instance.isGuest;

    return Scaffold(
      body: SafeArea(
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              sliver: SliverList.list(
                children: [
                  const _SectionHeader(eyebrow: 'EN LOCAL', count: 9),
                  const SizedBox(height: 16),
                  _GameGrid(games: _localGames, isGuest: isGuest),
                  const SizedBox(height: 36),
                  const _SectionHeader(eyebrow: 'EN LIGNE', count: 1),
                  const SizedBox(height: 16),
                  _GameGrid(games: _onlineGames, isGuest: isGuest),
                  const SizedBox(height: 36),
                  const _SectionHeader(eyebrow: 'OUTILS & FUN', count: 6),
                  const SizedBox(height: 16),
                  _GameGrid(games: _features, isGuest: isGuest),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.eyebrow, required this.count});
  final String eyebrow;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: theme.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          eyebrow,
          style: theme.overline.copyWith(
            color: theme.textPrimary,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: theme.overline.copyWith(
            color: theme.textMuted,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
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

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: theme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: theme.border, width: 1),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: theme.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        game.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyLarge.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked ? 'Compte requis' : game.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodyMedium.copyWith(
                          color: theme.textMuted,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (locked)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: theme.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
