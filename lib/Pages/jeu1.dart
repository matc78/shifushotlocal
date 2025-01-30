import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shifushotlocal/app_theme.dart'; // Import your AppTheme

class Jeu1 extends StatefulWidget {
  final List<String> players;

  const Jeu1({super.key, required this.players});

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

  void startGame() {
    setState(() {
      isGameActive = true;
      timeLeft = 10;
      buttonText = "Tap Me!";
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
                style: TextStyle(color: AppTheme.of(context).textPrimary), // Set text color
              ),
            const SizedBox(height: 20),
            Text(
              "Winner: $winner!",
              style: TextStyle(color: AppTheme.of(context).textPrimary), // Set text color
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to the lobby
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context); // Use AppTheme

    return Scaffold(
      backgroundColor: theme.background, // Set background color
      appBar: AppBar(
        title: const Text("Lancer Jeu 1"),
        backgroundColor: theme.primary, // Set app bar color
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
                color: theme.textPrimary, // Set text color
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Time Left: $timeLeft",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary, // Set text color
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Score: ${scores[currentPlayerIndex]}",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary, // Set text color
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: isGameActive ? incrementScore : startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary, // Set button color
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 20, color: Colors.white), // Set text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}