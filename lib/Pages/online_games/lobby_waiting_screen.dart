import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class LobbyWaitingScreen extends StatefulWidget {
  final String lobbyId;
  final bool isHost;

  const LobbyWaitingScreen({Key? key, required this.lobbyId, required this.isHost}) : super(key: key);

  @override
  _LobbyWaitingScreenState createState() => _LobbyWaitingScreenState();
}

class _LobbyWaitingScreenState extends State<LobbyWaitingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, String> playerNames = {}; // Stockage des prénoms
  late String userId;
  late bool isHost;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid;
    isHost = widget.isHost;
    _listenForPlayers();
  }

  @override
  void dispose() {
    _leaveLobby(); // Supprime le joueur du lobby s'il quitte l'écran
    super.dispose();
  }

  /// 🔹 **Écoute des mises à jour des joueurs en temps réel**
  void _listenForPlayers() {
    _firestore.collection('lobbies').doc(widget.lobbyId).snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;

      List<dynamic> playerIds = snapshot['players'] ?? [];
      String hostId = snapshot['hostId'] ?? "";

      // Vérifier si le lobby est vide et doit être supprimé
      if (playerIds.isEmpty) {
        await _firestore.collection('lobbies').doc(widget.lobbyId).delete();
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      // Vérifier si l'hôte a changé
      if (hostId == userId) {
        setState(() {
          isHost = true;
        });
      }

      // Mettre à jour les noms des joueurs
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
    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'isStarted': true,
    });
  }

  /// 🔹 **Un joueur quitte le lobby**
  Future<void> _leaveLobby() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference lobbyRef = _firestore.collection('lobbies').doc(widget.lobbyId);
    DocumentSnapshot lobbyDoc = await lobbyRef.get();

    if (lobbyDoc.exists) {
      List<dynamic> players = List.from(lobbyDoc['players']);
      players.remove(user.uid);

      if (players.isEmpty) {
        await lobbyRef.delete(); // Supprimer le lobby si personne dedans
      } else {
        if (user.uid == lobbyDoc['hostId']) {
          // 🔹 Transférer l'hôte si c'était l'hôte qui partait
          await lobbyRef.update({
            'players': players,
            'hostId': players.first, // Nouveau hôte
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
                Navigator.pushReplacementNamed(context, '/gamePage', arguments: players);
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
                    }).toList(),
                    const SizedBox(height: 30),
                    isHost
                        ? ElevatedButton(
                            onPressed: _startGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
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
