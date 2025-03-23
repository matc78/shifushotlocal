import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  _LobbyScreenState createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final List<String> players = [];
  final TextEditingController _playerController = TextEditingController();
  late String mode;
  late String gameName;
  List<String> remainingGames = [];

  final Map<String, String> gameRoutes = {
    'Clicker': '/clicker_game',
    'Bizkit !': '/dice_game',
    'Jeu des papiers': '/paper_game',
    'L\'horloge': '/clock_game',
  };

  final Map<String, int> minPlayersByRoute = {
    '/clicker_game': 1,
    '/dice_game': 1,
    '/paper_game': 3,
    '/clock_game': 2,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is String) {
      mode = 'Jeu';
      gameName = args;
      final route = gameRoutes[gameName];
      remainingGames = route != null ? [route, '/homepage'] : ['/homepage'];
    } else if (args is Map<String, dynamic>) {
      mode = args['mode'] ?? 'Soirée';
      gameName = args['gameName'] ?? 'Soirée';
      remainingGames = args['remainingGames'] ?? [];

      if (remainingGames.isEmpty) {
        final allGames = gameRoutes.values.toList();
        allGames.shuffle();
        remainingGames = allGames;
      }
    } else {
      mode = 'Jeu';
      gameName = 'Jeu';
      remainingGames = ['/homepage'];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserSurname();
  }

  Future<void> _fetchUserSurname() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final surname = userDoc.data()?['name'] ?? "Moi";
        if (mounted) setState(() => players.add(surname));
      } catch (_) {
        if (mounted) setState(() => players.add("Moi"));
      }
    }
  }

  void addPlayer() {
    if (_playerController.text.isNotEmpty) {
      setState(() {
        players.add(_playerController.text.trim());
        _playerController.clear();
      });
    }
  }

  void startSingleGame(String gameRoute, List<String> players) {
    final minPlayers = minPlayersByRoute[gameRoute] ?? 1;

    if (players.length < minPlayers) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Pas assez de joueurs"),
          content: Text("Ce jeu nécessite au moins $minPlayers joueur(s)."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    Navigator.pushNamed(context, gameRoute, arguments: {
      'players': players,
      'remainingGames': [],
    });
  }

  void startSoiree(List<String> players, List<String> games) {
    if (games.isEmpty) return;

    final firstGame = games.first;
    final minPlayers = minPlayersByRoute[firstGame] ?? 1;

    if (players.length < minPlayers) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Pas assez de joueurs"),
          content: Text("Le jeu suivant requiert au moins $minPlayers joueur(s)."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return;
    }

    Navigator.pushNamed(context, firstGame, arguments: {
      'players': players,
      'remainingGames': games.sublist(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          mode == 'Soirée' ? "Lobby - Soirée" : "Lobby - $gameName",
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () {
            if (mode == 'Soirée') {
              Navigator.pushReplacementNamed(context, '/homepage');
            } else {
              Navigator.pushReplacementNamed(context, '/select_game');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (mode == 'Soirée')
              Wrap(
                spacing: 8,
                children: remainingGames.map((route) {
                  final gameName = gameRoutes.entries.firstWhere(
                    (entry) => entry.value == route,
                    orElse: () => const MapEntry('Inconnu', ''),
                  ).key;
                  return Chip(label: Text(gameName));
                }).toList(),
              ),
            TextField(
              controller: _playerController,
              decoration: const InputDecoration(labelText: "Nom du joueur"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: addPlayer,
              child: const Text("Ajouter un joueur"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(players[index]),
                  trailing: index == 0
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => setState(() => players.removeAt(index)),
                        ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (mode == 'Soirée') {
                  startSoiree(players, remainingGames);
                } else {
                  startSingleGame(remainingGames.first, players);
                }
              },
              child: Text(mode == 'Soirée' ? "Commencer la soirée" : "Commencer le jeu"),
            ),
          ],
        ),
      ),
    );
  }
}