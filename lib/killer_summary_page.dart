import 'package:flutter/material.dart';
import 'app_theme.dart';

class KillerSummaryPage extends StatefulWidget {
  final Map<String, dynamic> playerData;

  const KillerSummaryPage({Key? key, required this.playerData}) : super(key: key);

  @override
  State<KillerSummaryPage> createState() => _KillerSummaryPageState();
}

class _KillerSummaryPageState extends State<KillerSummaryPage> {
  late Map<String, dynamic> playerData;
  late List<String> sortedPlayers;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    playerData = Map<String, dynamic>.from(widget.playerData);
    _sortPlayers();
    _checkGameOver();
  }

  void _sortPlayers() {
    sortedPlayers = playerData.keys.toList()..sort();
  }

  void _checkGameOver() {
    setState(() {
      isGameOver = playerData.values.where((player) => !player['isDead']).length <= 1;
    });
  }

  void _restartGame() {
    Navigator.pushReplacementNamed(context, '/killer');
  }

  void _checkPlayerAction(String playerName) {
    final theme = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Détails de l\'action', style: theme.titleMedium),
        content: Text(
          '${playerName} doit faire :\n\nAction : ${playerData[playerName]['action']}\nCible : ${playerData[playerName]['target']}',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer', style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }

  void _markPlayerAsDead(String playerName) {
    setState(() {
      // Trouver le joueur qui cible la personne éliminée
      final killer = playerData.keys.firstWhere(
        (name) => playerData[name]['target'] == playerName,
        orElse: () => '',
      );

      // Transférer la cible et l'action du joueur éliminé au joueur qui l'a tué
      playerData[killer]['target'] = playerData[playerName]['target'];
      playerData[killer]['action'] = playerData[playerName]['action'];

      // Marquer le joueur comme éliminé
      playerData[playerName]['isDead'] = true;

      // Vérifier si le jeu est terminé
      _checkGameOver();

      // Réordonner les joueurs en ordre alphabétique
      _sortPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (isGameOver) {
      final winner = playerData.keys.firstWhere((name) => !playerData[name]['isDead']);
      return Scaffold(
        appBar: AppBar(
          title: Text('Résumé du jeu', style: theme.titleMedium),
          backgroundColor: theme.background,
          centerTitle: true,
        ),
        backgroundColor: theme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Le jeu est terminé !',
                style: theme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Le gagnant est : $winner',
                style: theme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _restartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Recommencer', style: theme.buttonText),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Résumé du jeu', style: theme.titleMedium),
        backgroundColor: theme.background,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Résumé des joueurs',
              style: theme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: sortedPlayers.length,
                itemBuilder: (context, index) {
                  final playerName = sortedPlayers[index];
                  final player = playerData[playerName];
                  final isDead = player['isDead'];

                  return ListTile(
                    title: Text(
                      playerName,
                      style: isDead
                          ? theme.bodyMedium.copyWith(color: Colors.grey)
                          : theme.bodyLarge,
                    ),
                    subtitle: isDead
                        ? Text('Éliminé', style: theme.bodyMedium.copyWith(color: Colors.grey))
                        : null,
                    trailing: isDead
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.info, color: Colors.blue),
                                onPressed: () => _checkPlayerAction(playerName),
                              ),
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.red),
                                onPressed: () => _markPlayerAsDead(playerName),
                              ),
                            ],
                          ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Recommencer la partie', style: theme.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
