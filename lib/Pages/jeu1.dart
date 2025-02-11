import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shifushotlocal/app_theme.dart';

class Jeu1 extends StatefulWidget {
  final List<String> players;
  final List<String> remainingGames;

  const Jeu1({Key? key, required this.players, required this.remainingGames}) : super(key: key);

  @override
  _Jeu1State createState() => _Jeu1State();
}

class _Jeu1State extends State<Jeu1> {
  int currentPlayerIndex = 0;
  List<int> scores = [];
  bool isGameActive = false;
  bool showNextButton = false;
  bool showStartButton = true; // Affiche le bouton "C’EST PARTI !" au début
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
      showStartButton = true; // Réaffiche "C’EST PARTI !"
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
    startTimer(); // Démarre le timer
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

  void showGameOverDialog() {
    String winner = widget.players[scores.indexOf(scores.reduce((a, b) => a > b ? a : b))];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Final Scores:"),
            const SizedBox(height: 10),
            for (int i = 0; i < widget.players.length; i++)
              Text(
                "${widget.players[i]}: ${scores[i]}",
                style: TextStyle(color: AppTheme.of(context).textPrimary),
              ),
            const SizedBox(height: 20),
            Text(
              "Gagnant : $winner!",
              style: TextStyle(color: AppTheme.of(context).textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              navigateToNextGame();
            },
            child: const Text("OK"),
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

                  // Bouton "C'EST PARTI !" au début
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

                  // Bouton "Tap Me!" pendant le jeu
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

          // Bouton "Next Player" en bas
          if (showNextButton)
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
