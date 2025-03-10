import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

class KillerActionsPage extends StatefulWidget {
  final List<String> players;

  const KillerActionsPage({super.key, required this.players});

  @override
  State<KillerActionsPage> createState() => _KillerActionsPageState();
}

class _KillerActionsPageState extends State<KillerActionsPage> {
  int currentPlayerIndex = 0;
  String? currentAction;
  String? currentTarget;
  List<String> killerActions = [];
  final List<String> usedActions = [];
  final Map<String, dynamic> playerData = {};
  final List<String> shuffledPlayers = [];
  List<MapEntry<String, String>> shuffledTargetList = [];

  @override
  void initState() {
    super.initState();

    // Mélanger les joueurs pour attribuer des cibles dans un ordre circulaire
    shuffledPlayers.addAll(widget.players);
    shuffledPlayers.shuffle();

    // Assigner les cibles dans un ordre circulaire
    for (int i = 0; i < shuffledPlayers.length; i++) {
      final current = shuffledPlayers[i];
      final next = shuffledPlayers[(i + 1) % shuffledPlayers.length];
      playerData[current] = {
        'action': null,
        'target': next,
        'isDead': false,
      };
    }

    // Charger les actions depuis le fichier JSON
    _loadActions().then((_) {
      if (widget.players.length >= 3) {
        _assignActions();
        _initializeNextPlayer();
      } else {
        setState(() {
          currentAction = 'Pas assez de joueurs';
          currentTarget = null;
        });
      }
    });
  }

  Future<void> _loadActions() async {
    try {
      // Charger les actions depuis un fichier JSON
      final String response =
          await rootBundle.loadString('assets/jsons/killer_actions.json');
      final Map<String, dynamic> data = json.decode(response);

      // Extraire les actions sous la clé "autre"
      final List<String> actions = List<String>.from(data['autre'] ?? []);

      setState(() {
        killerActions = actions;
      });
    } catch (e) {
      print('Erreur lors du chargement des actions : $e');
    }
  }

  void _assignActions() {
    final availableActions = List<String>.from(killerActions);
    availableActions.shuffle();

    playerData.forEach((player, data) {
      if (availableActions.isNotEmpty) {
        data['action'] = availableActions.removeLast();
      }
    });
  }

  void _initializeNextPlayer() {
    setState(() {
      currentAction = playerData[shuffledPlayers[currentPlayerIndex]]['action'];
      currentTarget = playerData[shuffledPlayers[currentPlayerIndex]]['target'];
    });
  }

  void _nextPlayer() {
    if (currentPlayerIndex >= shuffledPlayers.length - 1) {
      // Log pour vérifier ce qui est envoyé
      print('Envoi vers KillerSummaryPage: $playerData');

      Navigator.pushReplacementNamed(
        context,
        '/killerSummary',
        arguments: playerData,
      );
      return;
    }

    setState(() {
      currentPlayerIndex++;
    });

    _initializeNextPlayer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Killer Actions', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: currentAction == null || currentTarget == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Confirmez que ${shuffledPlayers[currentPlayerIndex]} tient bien le téléphone à l\'abri des regards',
                    style: theme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Votre mission', style: theme.titleMedium),
                          content: Text(
                            '${shuffledPlayers[currentPlayerIndex]}, votre action est :\n\n $currentAction\n\nCible : $currentTarget',
                            style: theme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _nextPlayer();
                              },
                              child: const Text('Suivant'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Confirmer', style: theme.buttonText),
                  ),
                ],
              ),
            ),
    );
  }
}
