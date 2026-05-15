import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class LobbyWaitingScreen extends StatefulWidget {
  final String lobbyId;
  final bool isHost;
  final String gameRoute; // 🔹 Ajout de la route du jeu

  const LobbyWaitingScreen(
      {super.key,
      required this.lobbyId,
      required this.isHost,
      required this.gameRoute});

  @override
  State<LobbyWaitingScreen> createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends State<LobbyWaitingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, String> playerNames = {}; // Stockage des prénoms
  late String userId;
  late bool isHost;
  late StreamSubscription<DocumentSnapshot> _lobbySubscription;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid;
    isHost = widget.isHost;
    _listenForPlayers();
  }

  @override
  void dispose() {
    _lobbySubscription.cancel(); // 🔹 Arrêter le listener Firebase
    if (mounted) {
      _leaveLobby(
          onlyIfNotStarted:
              true); // 🔹 Vérifie si la partie est lancée avant de quitter
    }
    super.dispose();
  }

  /// 🔹 **Écoute des mises à jour des joueurs en temps réel**
  void _listenForPlayers() {
    _lobbySubscription = _firestore
        .collection('lobbies')
        .doc(widget.lobbyId)
        .snapshots()
        .listen((snapshot) async {
      if (!mounted) return; // 🔹 Vérifier que le widget est toujours actif

      if (!snapshot.exists) {
        if (mounted) {
          Navigator.pop(context); // 🔹 Quitter l'écran si le lobby est supprimé
        }
        return;
      }

      List<dynamic> playerIds = snapshot['players'] ?? [];
      String hostId = snapshot['hostId'] ?? "";

      if (playerIds.isEmpty) {
        await _firestore.collection('lobbies').doc(widget.lobbyId).delete();
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      if (hostId == userId) {
        setState(() {
          isHost = true;
        });
      }

      Map<String, String> updatedPlayerNames = {};
      for (String playerId in playerIds) {
        var userDoc = await _firestore.collection('users').doc(playerId).get();
        if (userDoc.exists) {
          updatedPlayerNames[playerId] = userDoc['name'] ?? 'Joueur inconnu';
        }
      }

      if (mounted) {
        setState(() {
          playerNames = updatedPlayerNames;
        });
      }
    });
  }

  /// 🔹 **Lancer la partie (uniquement pour l’hôte)**
  Future<void> _startGame() async {
    debugPrint("🟢 Tentative de démarrage du jeu...");

    final DocumentReference lobbyRef =
        _firestore.collection('lobbies').doc(widget.lobbyId);
    final DocumentSnapshot lobbyDoc = await lobbyRef.get();
    if (!mounted) return;

    if (!lobbyDoc.exists) {
      debugPrint("❌ Erreur : Le lobby n'existe pas.");
      return;
    }

    List<dynamic> players = lobbyDoc['players'] ?? [];
    final theme = AppTheme.of(context);
    // 🔹 Vérification du nombre de joueurs
    if (players.length < 2) {
      debugPrint("⚠️ Impossible de démarrer : il faut au moins 2 joueurs !");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Il faut au moins 2 joueurs pour commencer la partie !",
              style: theme.bodyLarge),
          duration: const Duration(seconds: 2),
          backgroundColor: theme.secondary,
        ),
      );
      return;
    }

    debugPrint("✅ Lobby trouvé, récupération des joueurs...");
    String gameRoute = widget.gameRoute;

    // 🔹 Marquer la partie comme commencée
    try {
      await lobbyRef.update({'isStarted': true});
      debugPrint("✅ Partie marquée comme commencée.");
    } catch (e) {
      debugPrint("❌ Erreur lors de la mise à jour du statut de la partie : $e");
      return;
    }

    // 🔹 Rediriger tous les joueurs
    for (String player in players) {
      try {
        await _firestore.collection('users').doc(player).update({
          'currentGame': {'lobbyId': widget.lobbyId, 'gameRoute': gameRoute},
        });
        debugPrint("✅ Joueur $player mis à jour avec le jeu en cours.");
      } catch (e) {
        debugPrint("❌ Erreur lors de la mise à jour du joueur $player : $e");
      }
    }

    // 🔹 Redirection immédiate de l'hôte
    if (mounted) {
      debugPrint("🚀 Redirection de l'hôte vers $gameRoute");
      Navigator.pushReplacementNamed(
        context,
        gameRoute,
        arguments: {'lobbyId': widget.lobbyId, 'players': players},
      );
    }

    debugPrint("🎉 Jeu lancé avec succès !");
  }

  /// 🔹 **Un joueur quitte le lobby**
  Future<void> _leaveLobby({bool onlyIfNotStarted = false}) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference lobbyRef =
        _firestore.collection('lobbies').doc(widget.lobbyId);
    DocumentSnapshot lobbyDoc = await lobbyRef.get();

    if (lobbyDoc.exists) {
      bool isStarted = lobbyDoc['isStarted'] ?? false;

      // 🔹 Ne pas supprimer les joueurs si la partie est commencée
      if (onlyIfNotStarted && isStarted) return;

      List<dynamic> players = List.from(lobbyDoc['players']);
      players.remove(user.uid);

      if (players.isEmpty) {
        await lobbyRef.delete(); // Supprimer le lobby si personne dedans
      } else {
        if (user.uid == lobbyDoc['hostId']) {
          await lobbyRef.update({
            'players': players,
            'hostId': players.first, // Transférer le rôle d'hôte
          });
        } else {
          await lobbyRef.update({'players': players});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) await _leaveLobby();
      },
      child: AppShell(
        title: 'Lobby en attente',
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app_rounded, color: theme.textPrimary),
            onPressed: () async {
              await _leaveLobby();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              _firestore.collection('lobbies').doc(widget.lobbyId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const EmptyState(
                icon: Icons.broken_image_rounded,
                title: 'Lobby supprimé',
                subtitle: "Le lobby n'existe plus.",
              );
            }
            final lobbyData = snapshot.data!;
            final players = List<dynamic>.from(lobbyData['players'] ?? []);
            final isStarted = lobbyData['isStarted'] ?? false;

            if (isStarted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(
                  context,
                  widget.gameRoute,
                  arguments: {
                    'lobbyId': widget.lobbyId,
                    'players': players,
                  },
                );
              });
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('CODE DU LOBBY',
                            style: theme.overline.copyWith(
                                color: theme.textMuted, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) =>
                                  theme.brandGradient.createShader(rect),
                              child: Text(
                                widget.lobbyId,
                                style: theme.displayLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 40,
                                  letterSpacing: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.content_copy_rounded,
                                  color: theme.primary),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: widget.lobbyId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Code copié !',
                                        style: theme.bodyMedium),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('JOUEURS CONNECTÉS (${players.length})',
                      style: theme.overline.copyWith(
                          color: theme.textPrimary, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: players.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final pid = players[i] as String;
                        final name = playerNames[pid] ?? 'Chargement…';
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
                                child: Text(name, style: theme.bodyLarge),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (isHost)
                    GradientButton(
                      label: 'Démarrer la partie',
                      icon: Icons.play_arrow_rounded,
                      onPressed: players.length < 2 ? null : _startGame,
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        "En attente de l'hôte…",
                        textAlign: TextAlign.center,
                        style: theme.bodyLarge
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 10),
                  GhostButton(
                    label: 'Quitter le lobby',
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      await _leaveLobby();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
