import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final List<String> players = [];
  final TextEditingController _playerController = TextEditingController();
  late String mode;
  late String gameName;
  List<String> remainingGames = [];

  final Map<String, String> gameRoutes = {
    'Clicker': Routes.clickerGame,
    'Bizkit !': Routes.diceGame,
    'Jeu des papiers': Routes.paperGame,
    "L'horloge": Routes.clockGame,
  };

  final Map<String, int> minPlayersByRoute = {
    Routes.clickerGame: 1,
    Routes.diceGame: 1,
    Routes.paperGame: 3,
    Routes.clockGame: 2,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      mode = 'Jeu';
      gameName = args;
      final route = gameRoutes[gameName];
      remainingGames = route != null ? [route, Routes.home] : [Routes.home];
    } else if (args is Map<String, dynamic>) {
      mode = args['mode'] ?? 'Soirée';
      gameName = args['gameName'] ?? 'Soirée';
      remainingGames = args['remainingGames'] ?? [];
      if (remainingGames.isEmpty) {
        final allGames = gameRoutes.values.toList()..shuffle();
        remainingGames = allGames;
      }
    } else {
      mode = 'Jeu';
      gameName = 'Jeu';
      remainingGames = [Routes.home];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() => players.add(doc.data()?['name'] as String? ?? 'Moi'));
    } catch (_) {
      if (mounted) setState(() => players.add('Moi'));
    }
  }

  void _addPlayer() {
    final name = _playerController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      players.add(name);
      _playerController.clear();
    });
  }

  void _start() {
    final firstGame =
        mode == 'Soirée' ? remainingGames.first : remainingGames.first;
    final min = minPlayersByRoute[firstGame] ?? 1;
    if (players.length < min) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pas assez de joueurs'),
          content: Text('Il faut au moins $min joueur(s).'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      firstGame,
      arguments: {
        'players': players,
        'remainingGames':
            mode == 'Soirée' ? remainingGames.sublist(1) : <String>[],
      },
    );
  }

  String? _routeToGameName(String route) {
    for (final entry in gameRoutes.entries) {
      if (entry.value == route) return entry.key;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isParty = mode == 'Soirée';
    return AppShell(
      title: isParty ? 'Lobby — Soirée' : 'Lobby — $gameName',
      onBack: () => Navigator.pushReplacementNamed(
        context,
        isParty ? Routes.home : Routes.selectGame,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isParty) ...[
              Text('AU PROGRAMME',
                  style: theme.overline
                      .copyWith(color: theme.textPrimary, letterSpacing: 2)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: remainingGames.map((route) {
                  final name = _routeToGameName(route) ?? 'Jeu';
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(color: theme.border),
                    ),
                    child: Text(name,
                        style: theme.bodyMedium
                            .copyWith(color: theme.textPrimary)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _playerController,
                    style: theme.bodyLarge,
                    decoration:
                        const InputDecoration(hintText: 'Nom du joueur'),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: GradientButton(
                    label: 'Ajouter',
                    onPressed: _addPlayer,
                    expanded: false,
                    height: 52,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: players.isEmpty
                  ? const EmptyState(
                      icon: Icons.group_outlined,
                      title: 'Aucun joueur',
                      subtitle: 'Ajoute des prénoms pour démarrer.',
                    )
                  : ListView.separated(
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final name = players[i];
                        final isMe = i == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: theme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: theme.brandGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: theme.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(name, style: theme.bodyLarge)),
                              if (!isMe)
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: theme.textMuted),
                                  onPressed: () =>
                                      setState(() => players.removeAt(i)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: isParty ? 'Commencer la soirée' : 'Commencer le jeu',
              icon: Icons.play_arrow_rounded,
              onPressed: _start,
            ),
          ],
        ),
      ),
    );
  }
}
