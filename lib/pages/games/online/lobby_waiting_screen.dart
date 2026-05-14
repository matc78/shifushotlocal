import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class LobbyWaitingScreen extends StatefulWidget {
  final String lobbyId;
  final bool isHost;
  final String gameRoute; // 🔹 Ajout de la route du jeu

  const LobbyWaitingScreen({super.key, required this.lobbyId, required this.isHost, required this.gameRoute});

  @override
  _LobbyWaitingScreenState createState() => _LobbyWaitingScreenState();
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
      _leaveLobby(onlyIfNotStarted: true); // 🔹 Vérifie si la partie est lancée avant de quitter
    }
    super.dispose();
  }


  /// 🔹 **Écoute des mises à jour des joueurs en temps réel**
  void _listenForPlayers() {
    _lobbySubscription = _firestore.collection('lobbies').doc(widget.lobbyId).snapshots().listen((snapshot) async {
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
    print("🟢 Tentative de démarrage du jeu...");

    final DocumentReference lobbyRef = _firestore.collection('lobbies').doc(widget.lobbyId);
    final DocumentSnapshot lobbyDoc = await lobbyRef.get();

    if (!lobbyDoc.exists) {
      print("❌ Erreur : Le lobby n'existe pas.");
      return;
    }

    List<dynamic> players = lobbyDoc['players'] ?? [];
    final theme = AppTheme.of(context);
    // 🔹 Vérification du nombre de joueurs
    if (players.length < 2) {
      print("⚠️ Impossible de démarrer : il faut au moins 2 joueurs !");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Il faut au moins 2 joueurs pour commencer la partie !", style: theme.bodyLarge),
          duration: Duration(seconds: 2),
          backgroundColor: theme.secondary,
        ),
      );
      return;
    }

    print("✅ Lobby trouvé, récupération des joueurs...");
    String gameRoute = widget.gameRoute;

    // 🔹 Marquer la partie comme commencée
    try {
      await lobbyRef.update({'isStarted': true});
      print("✅ Partie marquée comme commencée.");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour du statut de la partie : $e");
      return;
    }

    // 🔹 Rediriger tous les joueurs
    for (String player in players) {
      try {
        await _firestore.collection('users').doc(player).update({
          'currentGame': {
            'lobbyId': widget.lobbyId,
            'gameRoute': gameRoute
          },
        });
        print("✅ Joueur $player mis à jour avec le jeu en cours.");
      } catch (e) {
        print("❌ Erreur lors de la mise à jour du joueur $player : $e");
      }
    }

    // 🔹 Redirection immédiate de l'hôte
    if (mounted) {
      print("🚀 Redirection de l'hôte vers $gameRoute");
      Navigator.pushReplacementNamed(
        context,
        gameRoute,
        arguments: {'lobbyId': widget.lobbyId, 'players': players},
      );
    }

    print("🎉 Jeu lancé avec succès !");
  }


  /// 🔹 **Un joueur quitte le lobby**
  Future<void> _leaveLobby({bool onlyIfNotStarted = false}) async {
  final User? user = _auth.currentUser;
  if (user == null) return;

  DocumentReference lobbyRef = _firestore.collection('lobbies').doc(widget.lobbyId);
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
    return WillPopScope(
      onWillPop: () async {
        await _leaveLobby(); // Supprime le joueur du lobby en cas de retour arrière
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Lobby en attente", style: theme.titleMedium),
          backgroundColor: theme.background,
          elevation: 0,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await _leaveLobby();
                Navigator.pop(context);
              },
              color: theme.textPrimary,
            ),
          ],
        ),
        backgroundColor: theme.background,
        body: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('lobbies').doc(widget.lobbyId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text("Lobby supprimé ou introuvable", style: theme.bodyLarge),
              );
            }

            var lobbyData = snapshot.data!;
            List<dynamic> players = lobbyData['players'] ?? [];
            bool isStarted = lobbyData['isStarted'] ?? false;

            if (isStarted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(
                  context,
                  widget.gameRoute,
                  arguments: {
                    'lobbyId': widget.lobbyId,  // ✅ Pass the correct lobby ID
                    'players': players,
                  },
                );
              });
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Code du Lobby :\n ${widget.lobbyId}",
                      style: theme.bodyLarge.copyWith(fontSize: 35),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(width: 10), // 🔹 Espacement entre le texte et le bouton

                    // 🔹 Bouton de copie
                    IconButton(
                      icon: Icon(Icons.content_copy, color: theme.primary, size: 20), // ✅ Icône de copie
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.lobbyId)); // ✅ Copie dans le presse-papier
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: theme.background,
                            content: Text("Code copié !", style: theme.bodyLarge), // ✅ Confirmation
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                    Text(
                      "Joueurs connectés :",
                      style: theme.titleMedium.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: 10),
                    ...players.map((playerId) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: Text(
                          playerNames[playerId] ?? "Chargement...",
                          style: theme.bodyLarge.copyWith(fontSize: 24),
                        ),
                      );
                    }),
                    const SizedBox(height: 30),
                    isHost
                      ? ElevatedButton(
                          onPressed: players.length < 2 ? null : _startGame, // ✅ Désactive si moins de 2 joueurs
                          style: ElevatedButton.styleFrom(
                            backgroundColor: players.length < 2 ? Colors.grey : theme.primary, // ✅ Grise le bouton
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text("Démarrer la Partie", style: theme.buttonText),
                        )
                      : Text(
                          "En attente de l'hôte...",
                          style: theme.bodyLarge.copyWith(fontStyle: FontStyle.italic),
                        ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _leaveLobby();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.secondary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("Quitter le Lobby", style: theme.buttonText),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
