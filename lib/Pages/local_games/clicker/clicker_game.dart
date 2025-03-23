import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shifushotlocal/theme/app_theme.dart';

class ClickerGame extends StatefulWidget {
  final List<String> players;
  final List<String> remainingGames;

  const ClickerGame({super.key, required this.players, required this.remainingGames});

  @override
  _ClickerGameState createState() => _ClickerGameState();
}

class _ClickerGameState extends State<ClickerGame> {
  int currentPlayerIndex = 0;
  List<int> scores = [];
  bool isGameActive = false;
  bool showNextButton = false;
  bool showStartButton = true;
  Timer? timer;
  int timeLeft = 10;

  @override
  void initState() {
    super.initState();
    scores = List.filled(widget.players.length, 0);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isGameActive = false;
      showNextButton = false;
      showStartButton = true;
      timeLeft = 10;
    });
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        timeLeft--;
      });

      if (timeLeft <= 0) {
        timer.cancel();
        endTurn();
      }
    });
  }

  void incrementScore() {
    if (!isGameActive) return;
    setState(() {
      scores[currentPlayerIndex]++;
    });
  }

  void startClickingPhase() {
    setState(() {
      isGameActive = true;
      showStartButton = false;
    });
    startTimer();
  }

  void endTurn() {
    setState(() {
      isGameActive = false;
      showNextButton = true;
    });

    if (currentPlayerIndex < widget.players.length - 1) {
      currentPlayerIndex++;
      timeLeft = 10;
    } else {
      showGameOverDialog();
    }
  }

  void navigateToNextGame() {
    if (widget.remainingGames.isNotEmpty) {
      Navigator.pushNamed(
        context,
        widget.remainingGames.first,
        arguments: {
          'players': widget.players,
          'remainingGames': widget.remainingGames.sublist(1),
        },
      );
    } else {
      Navigator.pushNamed(context, '/homepage');
    }
  }

  void showGameOverDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final int currentScore = scores[0];

    if (uid != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      try {
        final doc = await docRef.get();
        final data = doc.data() ?? {};
        final highScores = Map<String, dynamic>.from(data['high_scores'] ?? {});
        final int existingScore = (highScores['clicker_game'] ?? 0) as int;

        if (currentScore > existingScore) {
          highScores['clicker_game'] = currentScore;
          await docRef.update({'high_scores': highScores});
          print("🎉 Nouveau record personnel : $currentScore");
        } else {
          print("ℹ️ Score actuel : $currentScore (record : $existingScore)");
        }
      } catch (e) {
        print("❌ Erreur mise à jour du high score : $e");
      }
    }

    String winner = widget.players[scores.indexOf(scores.reduce((a, b) => a > b ? a : b))];

    await Future.delayed(const Duration(seconds: 1));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Final Scores:",
              style: TextStyle(
                fontSize: 20, 
                color: AppTheme.of(context).textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < widget.players.length; i++)
              Text(
                "${widget.players[i]}: ${scores[i]}",
                style: TextStyle(
                  fontSize: 20, 
                  color: AppTheme.of(context).textPrimary,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "Gagnant : $winner!",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: AppTheme.of(context).textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ClickerGame(
                    players: widget.players,
                    remainingGames: widget.remainingGames,
                  ),
                ),
              );
            },
            child: const Text("Rejouer avec les mêmes joueurs"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/Pages/lobby_screen');
            },
            child: const Text("Changer les joueurs"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/homepage');
            },
            child: const Text("Retour à l'accueil"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          "Le Clicker",
          style: theme.titleMedium,
        ),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Tour de ${widget.players[currentPlayerIndex]}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Temps restant : $timeLeft",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Score: ${scores[currentPlayerIndex]}",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (showStartButton)
                    ElevatedButton(
                      onPressed: startClickingPhase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "C'EST PARTI !",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  if (!showStartButton && !showNextButton)
                    ElevatedButton(
                      onPressed: incrementScore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        "TAPE MOI !!\nMAIS TAPE PLUS VITE !!\nP****N J'ADORE ÇA !!",
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showNextButton && currentPlayerIndex < widget.players.length - 1)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    showNextButton = false;
                    startGame();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                ),
                child: const Text(
                  "Prochain Joueur",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}