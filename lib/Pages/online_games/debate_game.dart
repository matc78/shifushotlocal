import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;


class DebateGameScreen extends StatefulWidget {
  final String lobbyId;

  const DebateGameScreen({super.key, required this.lobbyId});

  @override
  _DebateGameScreenState createState() => _DebateGameScreenState();
}

class _DebateGameScreenState extends State<DebateGameScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;
  String role = "";
  bool showRole = true;
  Map<String, dynamic> players = {};
  String? eliminatedPlayer;
  Map<String, int> votes = {};
  bool votingComplete = false;
  final bool _rolesAssigned = false; // ✅ Ajout du flag
  Map<String, String> playerNames = {}; // Stockage des prénoms
  Map<String, bool> hasVoted = {}; // Indique qui a voté
  int totalVotes = 0; // Nombre de votes exprimés
  bool _namesFetched = false;
  StreamSubscription<DocumentSnapshot>? _voteSubscription;
  Set<String> eliminatedPlayers = {};
  bool showRolePopup = false;
  String civilDebate = ""; // Débat affiché aux civils
  String debateWord1 = "";
  String debateWord2 = "";
  int _currentTurn = 1; // ✅ Compteur des tours
  String? currentSpeaker; // ✅ Joueur qui commence à parler
  List<String> voteMessages = [];


  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser!.uid;
    _checkAndAssignRoles();
    _listenForVotes(); // 🔄 Écoute des votes en temps réel
    _fetchPlayerNames(); // 🔹 Récupérer les noms des joueurs
    _listenForGameEnd(); // 🏁 Vérifie la fin de la partie

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => showRole = false);
      }
    });
  }


  Future<void> _checkAndAssignRoles() async {
  DocumentSnapshot lobbyDoc = await _firestore.collection('lobbies').doc(widget.lobbyId).get();
  if (!lobbyDoc.exists) {
    print("❌ Erreur : Lobby introuvable.");
    return;
  }

  Map<String, dynamic>? lobbyData = lobbyDoc.data() as Map<String, dynamic>?;
  if (lobbyData == null) return;

  // ✅ Vérifie si les rôles ET le débat sont déjà assignés
  if (lobbyData.containsKey('roles') && lobbyData.containsKey('debate')) {
    print("⏭️ Rôles et débat déjà assignés, récupération...");
    if (mounted) {
      setState(() {
        players = Map<String, dynamic>.from(lobbyData['roles']);
        role = players[userId] ?? "Civil";
        debateWord1 = lobbyData['debate']['word1'] ?? "???";
        debateWord2 = lobbyData['debate']['word2'] ?? "???";
        civilDebate = "$debateWord1 vs $debateWord2";
      });
    }
  } else {
    // 🚀 Seul l'hôte assigne les rôles et choisit un débat
    if (lobbyData['hostId'] == userId) {
      await _assignRoles();
    } else {
      print("⏳ Attente des rôles et du débat...");
    }
  }
}


  Future<void> _assignRoles() async {
    if (_rolesAssigned) return; // ✅ Vérification de sécurité

    print("🟢 Vérification du rôle de l'hôte...");
    DocumentSnapshot lobbyDoc = await _firestore.collection('lobbies').doc(widget.lobbyId).get();
    if (!lobbyDoc.exists) {
      print("❌ Erreur : Le lobby n'existe pas.");
      return;
    }

    Map<String, dynamic>? lobbyData = lobbyDoc.data() as Map<String, dynamic>?;
    if (lobbyData == null) return;

    // Vérifier si l'utilisateur est l'hôte
    String hostId = lobbyData['hostId'];
    bool isHost = (userId == hostId);

    // Si les rôles existent déjà, on les récupère plutôt que de les réattribuer
    if (lobbyData.containsKey('roles') && lobbyData.containsKey('debate')) {
      print("⏭️ Rôles et débat déjà assignés, récupération...");
      if (mounted) {
        setState(() {
          players = Map<String, dynamic>.from(lobbyData['roles']);
          role = players[userId] ?? "Civil";
          debateWord1 = lobbyData['debate']['word1'] ?? "???";
          debateWord2 = lobbyData['debate']['word2'] ?? "???";
          civilDebate = "$debateWord1 vs $debateWord2";
        });
        print("✅ Rôles récupérés : $players, Débat -> $debateWord1 vs $debateWord2");
      }
      return;
    }

    // L'hôte attribue les rôles et choisit un débat
    if (isHost) {
      print("👑 Cet utilisateur est l'hôte. Attribution des rôles et choix du débat...");

      List<dynamic> playerIds = List.from(lobbyData['players'] ?? []);
      List<dynamic> nonEliminated = playerIds;
      nonEliminated.shuffle();
      String firstSpeaker = nonEliminated.first;
      playerIds.shuffle(); // Mélange des joueurs
      String impostor = playerIds.first; // Premier joueur = imposteur
      

      Map<String, dynamic> assignedRoles = {};
      for (String id in playerIds) {
        assignedRoles[id] = (id == impostor) ? "Imposteur" : "Civil";
      }

      // 🔥 Génération et stockage du débat
      List<String> chosenDebate = await _chooseDebate();
      String debate1 = chosenDebate[0];
      String debate2 = chosenDebate[1];

      // 🔄 Mise à jour Firestore
      await _firestore.collection('lobbies').doc(widget.lobbyId).update({
        'roles': assignedRoles,
        'debate': {'word1': debate1, 'word2': debate2},
        'currentTurn': 1, // ✅ Tour 1
        'currentSpeaker': firstSpeaker, // ✅ Premier joueur choisi
      });

      print("✅ Rôles et débat enregistrés : $assignedRoles, Débat -> $debate1 vs $debate2");
    } else {
      print("⏳ Cet utilisateur n'est pas l'hôte. Attente des rôles et du débat...");
    }

    // 🔹 Récupérer les rôles et le débat après mise à jour (pour tout le monde)
    DocumentSnapshot updatedLobbyDoc = await _firestore.collection('lobbies').doc(widget.lobbyId).get();
    
    if (updatedLobbyDoc.exists) {
      Map<String, dynamic> updatedData = updatedLobbyDoc.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          players = Map<String, dynamic>.from(updatedData['roles']);
          role = players[userId] ?? "Civil";
          debateWord1 = updatedData['debate']['word1'] ?? "???";
          debateWord2 = updatedData['debate']['word2'] ?? "???";
          civilDebate = "$debateWord1 vs $debateWord2";
        });
      }
    }
  }


  Future<List<String>> _chooseDebate() async {
    try {
      // Charge le fichier JSON contenant les débats
      String jsonString = await rootBundle.loadString('assets/jsons/debate.json');
      List<dynamic> rawDebates = json.decode(jsonString);

      // Vérifie que chaque élément est une liste de 2 chaînes
      List<List<String>> debates = rawDebates.map((debate) => List<String>.from(debate)).toList();

      if (debates.isNotEmpty) {
        return debates[DateTime.now().millisecondsSinceEpoch % debates.length]; // Sélection aléatoire
      }
    } catch (e) {
      print("⚠️ Erreur lors du chargement du débat : $e");
    }
    return ["Erreur", "Débat introuvable"]; // Valeur de secours en cas d'erreur
  }


  Future<void> _fetchPlayerNames() async {

    if (_namesFetched) return; // ✅ Empêcher les appels multiples
    _namesFetched = true;
    DocumentSnapshot lobbyDoc = await _firestore.collection('lobbies').doc(widget.lobbyId).get();
    if (!lobbyDoc.exists) return;

    List<dynamic> playerIds = List.from(lobbyDoc['players'] ?? []);
    Map<String, String> names = {};

    for (String playerId in playerIds) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(playerId).get();
      if (userDoc.exists) {
        names[playerId] = userDoc['name'] ?? "Joueur inconnu";
      }
    }

    if (mounted) { // ✅ Vérifie si le widget est toujours dans l’arbre avant `setState()`
      setState(() {
        playerNames = names;
      });
    }

    print("✅ Noms des joueurs récupérés : $playerNames");
  }


  @override
  void dispose() {
    _voteSubscription?.cancel(); // ✅ Annule l'écoute Firestore
    super.dispose();
  }


  void _listenForVotes() {
    _firestore.collection('lobbies').doc(widget.lobbyId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      Map<String, dynamic>? data = snapshot.data();
      if (data == null) return;

      // 🔹 Mise à jour des votes et des joueurs qui ont voté
      Map<String, int> updatedVotes = Map<String, int>.from(data['votes'] ?? {});
      Map<String, bool> updatedHasVoted = Map<String, bool>.from(data['hasVoted'] ?? {});
      List<String> updatedVoteMessages = List<String>.from(data['voteMessages'] ?? []);

      // 🔹 Récupération du tour actuel et du joueur qui commence
      int updatedTurn = data.containsKey('currentTurn') ? data['currentTurn'] : _currentTurn;
      String? updatedSpeaker = data.containsKey('currentSpeaker') ? data['currentSpeaker'] : currentSpeaker;

      // 🔹 Vérifier si le jeu est terminé (stocké dans Firestore)
      String? gameOverMessage = data.containsKey('gameOverMessage') ? data['gameOverMessage'] : null;

      if (mounted) {
        setState(() {
          votes = updatedVotes;
          hasVoted = updatedHasVoted;
          voteMessages = updatedVoteMessages;
          _currentTurn = updatedTurn;
          currentSpeaker = updatedSpeaker;
          
          // 🔹 On ne compte que les votes des joueurs NON éliminés
          totalVotes = updatedVotes.values.fold(0, (sum, val) => sum + val);
          int remainingPlayers = players.isNotEmpty 
              ? players.keys.where((id) => !eliminatedPlayers.contains(id)).length
              : 0;

          print("🗳 Total Votes: $totalVotes / $remainingPlayers");

          // ✅ Vérifier si tous les survivants ont voté et lancer l'élimination
          if (totalVotes >= remainingPlayers && !votingComplete) {
            _eliminatePlayer();
          }

          // ✅ Vérifier si la partie est terminée et afficher le message
          if (gameOverMessage != null && gameOverMessage.isNotEmpty) {
            _endGame(gameOverMessage);
          }
        });
      }
    });
  }


  Future<void> _votePlayer(String targetPlayerId) async {
    if (hasVoted[userId] == true) return; // Empêcher de voter plusieurs fois
    print("📩 Vote pour éliminer : $targetPlayerId");

    String voterName = playerNames[userId] ?? "Inconnu";
    //String targetName = playerNames[targetPlayerId] ?? "Inconnu";

    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'votes.$targetPlayerId': FieldValue.increment(1),
      'hasVoted.$userId': true,
      'voteMessages': FieldValue.arrayUnion(["$voterName a voté"]),
    });

    setState(() {
      hasVoted[userId] = true; // Désactive le bouton immédiatement sur l'UI
    });
  }


  void _eliminatePlayer() async {
  if (votes.isEmpty) return;

  String playerToEliminate = votes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  String eliminatedName = playerNames[playerToEliminate] ?? "Joueur inconnu";

  print("❌ Joueur éliminé : $playerToEliminate");

  eliminatedPlayers.add(playerToEliminate);

  await _firestore.collection('lobbies').doc(widget.lobbyId).update({
    'eliminated': playerToEliminate,
    'votes': {}, 
    'hasVoted': {}, 
    'voteMessages': FieldValue.arrayUnion(["💀 $eliminatedName a été éliminé !"]),
  });

  if (mounted) {
    setState(() {
      eliminatedPlayer = playerToEliminate;
      votingComplete = true;
    });
  }

  await Future.delayed(const Duration(seconds: 5));

  if (players[playerToEliminate] == "Imposteur") {
    _askImpostorGuess(playerToEliminate);
  } else {
    _checkGameEnd(playerToEliminate);
  }
}


  void _askImpostorGuess(String impostorId) {
  if (userId != impostorId) return; // 🔹 Seul l'imposteur voit le pop-up

  TextEditingController guessController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("🔮 Devinez un mot"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("L'imposteur a été éliminé !\nIl peut encore gagner en devinant un des mots du débat."),
          const SizedBox(height: 10),
          TextField(
            controller: guessController,
            decoration: const InputDecoration(hintText: "Entrez un mot"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            String guess = guessController.text.trim().toLowerCase(); // 🔥 Suppression espaces + mise en minuscule
            String word1 = debateWord1.trim().toLowerCase();
            String word2 = debateWord2.trim().toLowerCase();

            bool impostorWins = (guess == word1 || guess == word2);

            String gameOverMessage = impostorWins
                ? "👿 L'imposteur a gagné en devinant '$guess' !"
                : "🎉 Les civils ont gagné !";

            print("🔮 L'imposteur a deviné : $guess, mots : $debateWord1 / $debateWord2");

            Navigator.pop(context); // 🔄 Ferme la boîte de dialogue

            // 🔥 Écrire dans Firestore que la partie est terminée
            await _firestore.collection('lobbies').doc(widget.lobbyId).update({
              'gameOverMessage': gameOverMessage,
            });

          },
          child: const Text("Valider"),
        ),
      ],
    ),
  );
}


  void _listenForGameEnd() {
    _firestore.collection('lobbies').doc(widget.lobbyId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      Map<String, dynamic>? data = snapshot.data();
      if (data == null) return;

      if (data.containsKey('gameOverMessage')) {
        String message = data['gameOverMessage'];

        print("🏁 Fin de partie détectée : $message");

        if (mounted) {
          _endGame(message); // 🚀 Affiche le message de fin de partie à tout le monde
        }
      }
    });
  }



  void _checkGameEnd(String eliminatedPlayer) {
  print("🔍 Vérification de la fin de partie...");

  // Fin du jeu si l'imposteur est éliminé
  if (players[eliminatedPlayer] == "Imposteur") {
    _endGame("🎉 Les civils ont gagné !");
    return;
  }

  // Vérification du nombre de joueurs restants
  int remainingPlayers = players.keys.where((playerId) => !eliminatedPlayers.contains(playerId)).length;

  if (remainingPlayers == 1) {
    _endGame("👿 L'imposteur a gagné !");
    return;
  }

  // Relance un nouveau vote avec les joueurs actifs
  _startNewVote();
}



  Future<void> _startNewVote() async {
    print("🔄 Nouveau vote lancé...");
    
    // Sélectionner un nouveau joueur qui commence à parler (parmi ceux non éliminés)
    List<String> remainingPlayers = players.keys.where((id) => !eliminatedPlayers.contains(id)).toList();
    if (remainingPlayers.isNotEmpty) {
      remainingPlayers.shuffle();
      currentSpeaker = remainingPlayers.first;
    }

    // 🔹 Incrémenter le tour
    _currentTurn++;

    await _firestore.collection('lobbies').doc(widget.lobbyId).update({
      'votes': {}, // Reset votes
      'hasVoted': {}, // Reset qui a voté
      'voteMessages': [], // Nettoyer les messages pour un nouveau tour
      'currentTurn': _currentTurn,
      'currentSpeaker': currentSpeaker, // Stocke qui parle en premier
    });

    if (mounted) {
      setState(() {
        eliminatedPlayer = null;
        votingComplete = false;
      });
    }
  }



  void _endGame(String message) {
    print("🏁 Fin de la partie : $message");

    showDialog(
      context: context,
      barrierDismissible: false, // Empêche de fermer sans cliquer sur le bouton
      builder: (_) => AlertDialog(
        title: const Text("Fin de Partie"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              await _leaveLobby(); // Supprime le joueur du lobby
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, "/homepage", (route) => false);
              }
            },
            child: const Text("🏠 Retourner à l'accueil"),
          ),
        ],
      ),
    );
  }



  Future<void> _leaveLobby() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference lobbyRef = _firestore.collection('lobbies').doc(widget.lobbyId);
    DocumentSnapshot lobbyDoc = await lobbyRef.get();

    if (!lobbyDoc.exists) return;

    List<dynamic> playersList = List.from(lobbyDoc['players']);
    playersList.remove(user.uid);

    if (playersList.isEmpty) {
      // 🚨 Supprime le lobby si plus personne
      await lobbyRef.delete();
      if (kDebugMode) {
        print("🏁 Lobby supprimé car plus aucun joueur.");
      }
    } else {
      // 🔄 Met à jour le lobby avec un nouvel hôte
      await lobbyRef.update({
        'players': playersList,
        'hostId': playersList.first, // Nouveau hôte
      });
    }

    if (kDebugMode) {
      print("🚪 Joueur ${user.uid} a quitté le lobby.");
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('lobbies').doc(widget.lobbyId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(child: Text("Lobby introuvable", style: theme.titleLarge)),
          );
        }

        var lobbyData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        if (!lobbyData.containsKey('roles')) {
          if (lobbyData['hostId'] == userId) {
            if (kDebugMode) {
              print("👑 Hôte détecté, attribution des rôles...");
            }
            _assignRoles();
          } else {
            if (kDebugMode) {
              print("⏳ En attente des rôles...");
            }
          }
        } else {
          players = Map<String, dynamic>.from(lobbyData['roles']);
          role = players[userId] ?? "Civil";
        }

        // 📌 Affichage du rôle au début de la partie
        if (showRole) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    playerNames[userId] ?? "Joueur inconnu",
                    style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Votre rôle : $role",
                    style: theme.titleLarge,
                  ),
                  if (role == "Civil") // 🔹 Affiche uniquement pour les civils
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        "🎭 Débat : $civilDebate",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: theme.background, // ✅ Fond de l'application
          appBar: AppBar(
            title: const Text("Jeu du débat"),
            backgroundColor: theme.background, // ✅ Couleur de l'AppBar
            foregroundColor: theme.primary, // ✅ Texte en blanc
            actions: [
              IconButton(
                icon: Icon(Icons.info_outline, color: theme.primary), // ✅ Icône rouge
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: theme.background, // ✅ Adaptation du thème
                      title: Text("📜 Règles du jeu", style: theme.titleMedium),
                      content: Text(
                        "Les joueurs civils doivent identifier l’imposteur en débattant sur le sujet affiché.\n\n"
                        "L’imposteur doit essayer de semer le doute sans se faire découvrir.\n\n"
                        "À chaque tour, les joueurs votent pour éliminer un suspect. La partie se termine lorsque l’imposteur est découvert ou qu’il reste seul.",
                        textAlign: TextAlign.justify,
                        style: theme.bodyMedium,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("OK", style: theme.bodyLarge),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Text("Joueurs :", style: theme.titleMedium),
              Expanded(
                child: ListView(
                  children: players.keys.map((playerId) {
                    bool isEliminated = eliminatedPlayers.contains(playerId);
                    bool isCurrentUserEliminated = eliminatedPlayers.contains(userId);
                    bool canVote = !isEliminated && !isCurrentUserEliminated && hasVoted[userId] != true && !votingComplete;

                    return ListTile(
                      title: Text(
                        playerNames[playerId] ?? "Joueur inconnu",
                        style: TextStyle(
                          color: isEliminated ? Colors.grey : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: isEliminated || isCurrentUserEliminated
                          ? null
                          : canVote
                              ? ElevatedButton(
                                  onPressed: () => _votePlayer(playerId),
                                  child: const Text("Voter"),
                                )
                              : const Text("✔️ A voté", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              ),

              // 🔹 Tour actuel et joueur qui commence
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Text("Tour $_currentTurn", style: theme.titleMedium.copyWith(fontWeight: FontWeight.bold)), // ✅ Affichage du tour
                    if (currentSpeaker != null && playerNames.containsKey(currentSpeaker))
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          "🎙 ${playerNames[currentSpeaker]!} commence ce tour.",
                          style: theme.bodyMedium.copyWith(color: theme.secondary, fontWeight: FontWeight.bold), // ✅ Rouge + Gras
                        ),
                      ),
                  ],
                ),
              ),

              // 🔹 Bouton "Voir mon rôle"
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.buttonColor, // ✅ Couleur du bouton
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // ✅ Arrondi
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: theme.background, // ✅ Fond de l'alerte
                        title: Text("Votre rôle", style: theme.titleMedium),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Vous êtes : $role",
                              style: theme.bodyLarge.copyWith(fontSize: 20, fontWeight: FontWeight.bold), // ✅ Augmenté à 24px
                            ),
                            if (role == "Civil")
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Text(
                                  "🎭 Débat : $civilDebate",
                                  textAlign: TextAlign.center,
                                  style: theme.bodyMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: theme.secondary), // ✅ Augmenté à 22px
                                ),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("OK", style: theme.bodyLarge),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text("👀 Voir mon rôle", style: theme.buttonText), // ✅ Texte stylisé
                ),
              ),

              // 🔹 Liste des votes en temps réel
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: voteMessages.map((message) => Text(message, style: theme.bodyLarge)).toList(),
                ),
              ),

              // 🔹 Affichage du joueur éliminé avec son rôle
              if (eliminatedPlayer != null)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        "💀 ${playerNames[eliminatedPlayer] ?? "Joueur inconnu"} a été éliminé !",
                        style: theme.titleMedium.copyWith(color: theme.secondary), // ✅ Texte rouge
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Son rôle était : ${players[eliminatedPlayer] ?? "Inconnu"}",
                        style: theme.bodyMedium.copyWith(color: theme.textSecondary), // ✅ Couleur secondaire
                      ),
                    ],
                  ),
                ),

              // 🔹 Affichage du message "En attente des votes"
              if (!votingComplete)
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "🕒 En attente du vote des autres joueurs... $totalVotes/${players.length - eliminatedPlayers.length}",
                    style: theme.bodyMedium.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}