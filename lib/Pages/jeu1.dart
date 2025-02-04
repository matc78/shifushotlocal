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
  String buttonText = "Start Game";
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
      isGameActive = true;
      timeLeft = 10;
      buttonText = "Tap Me!";
    });

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
    if (isGameActive) {
      setState(() {
        scores[currentPlayerIndex]++;
      });
    }
  }

  void endTurn() {
    setState(() {
      isGameActive = false;
      buttonText = "Next Player";
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
        widget.remainingGames.first, // Next game
        arguments: {
          'players': widget.players,
          'remainingGames': widget.remainingGames.sublist(1), // Remaining games
        },
      );
    } else {
      Navigator.pushNamed(context, '/homepage'); // Navigate to homepage
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
              "Winner: $winner!",
              style: TextStyle(color: AppTheme.of(context).textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              navigateToNextGame(); // Navigate to the next game or homepage
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Current Player: ${widget.players[currentPlayerIndex]}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Time Left: $timeLeft",
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
            ElevatedButton(
              onPressed: isGameActive ? incrementScore : startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
