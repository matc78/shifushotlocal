// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shifushotlocal/app_theme.dart';

class PaperGamePlayPage extends StatefulWidget {
  final List<Map<String, dynamic>> papers;
  final List<String> players;

  const PaperGamePlayPage({Key? key, required this.papers, required this.players}) : super(key: key);

  @override
  _PaperGamePlayPageState createState() => _PaperGamePlayPageState();
}

class _PaperGamePlayPageState extends State<PaperGamePlayPage> {
  int currentPlayerIndex = 0;
  String displayedText = "Appuyez pour tirer un papier";
  bool isDrawing = false;
  bool hasDrawn = false;
  Map<String, dynamic>? selectedPaper;
  Map<String, int> shotCounter = {};
  List<Map<String, dynamic>> remainingPapers = [];

  @override
  void initState() {
    super.initState();
    remainingPapers = List.from(widget.papers); // Copie des papiers pour éviter la modification de la liste d'origine
    for (var player in widget.players) {
      shotCounter[player] = 0;
    }
  }

  void _drawPaper() {
    if (remainingPapers.isEmpty) {
      _endGame();
      return;
    }

    // Sélection aléatoire d’un papier
    setState(() {
      int randomIndex = Random().nextInt(remainingPapers.length);
      selectedPaper = remainingPapers[randomIndex];
      remainingPapers.removeAt(randomIndex);

      hasDrawn = true;
      displayedText = "\"${selectedPaper!['text']}\"";
    });
  }


  void _acceptPaper() {
    _nextPlayer();
  }

  void _refusePaper() {
    final targetPlayer = selectedPaper!['player'] == 'Celui qui piochera'
        ? widget.players[currentPlayerIndex]
        : selectedPaper!['player'];

    setState(() {
      shotCounter[targetPlayer] = (shotCounter[targetPlayer] ?? 0) + 1;
      _nextPlayer();
    });

    showDialog(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        return AlertDialog(
          backgroundColor: theme.background,
          title: Text("Refus !", style: theme.titleMedium),
          content: Text(
            "$targetPlayer doit boire ${shotCounter[targetPlayer]} shot(s) !",
            style: theme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK", style: theme.buttonText.copyWith(color: theme.primary)),
            ),
          ],
        );
      },
    );
  }

  void _nextPlayer() {
    if (remainingPapers.isEmpty) {
      _endGame();
      return;
    }

    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % widget.players.length;
      displayedText = "Au tour de ${widget.players[currentPlayerIndex]}";
      hasDrawn = false;
      selectedPaper = null;
    });
  }

  void _endGame() {
    final theme = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.background,
        title: Text("Fin du jeu", style: theme.titleMedium),
        content: Text("Tous les papiers ont été joués.", style: theme.bodyLarge),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text("Retour à l'accueil", style: theme.buttonText.copyWith(color: theme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currentPlayer = widget.players[currentPlayerIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("Jeu du papier", style: theme.titleMedium),
        backgroundColor: theme.background,
        centerTitle: true,
      ),
      backgroundColor: theme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Tour de $currentPlayer",
              style: theme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            if (hasDrawn)
              Stack(
                alignment: Alignment.center,
                children: [
                  // Image d'arrière-plan
                  Transform.rotate(
                    angle: -pi / 2, // Rotation de 90° en radians
                    child: Image.asset(
                      'assets/images/papier_dechire.png',
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.6, // Ajuste la largeur à 90% de l'écran
                    ),
                  ),
                  // Texte superposé
                  Column(
                    children: [
                      Text(
                        "Cible : ${selectedPaper!['player'] == 'Celui qui piochera' ? currentPlayer : selectedPaper!['player']}",
                        style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 25),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayedText,
                        style: theme.bodyLarge.copyWith(fontSize: 22),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 30),
            if (!hasDrawn)
              ElevatedButton(
                onPressed: isDrawing ? null : _drawPaper,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Tirer un papier", style: theme.buttonText.copyWith(fontSize: 18)),
              ),
            if (hasDrawn) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _acceptPaper,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    ),
                    child: Text("J'accepte", style: theme.buttonText),
                  ),
                  Column(
                    children: [
                      Text(
                        "Pénalité (Shots) : ${shotCounter[selectedPaper!['player'] ?? ''] ?? 0}",
                        style: theme.bodyMedium.copyWith(color: theme.secondary),
                      ),
                      ElevatedButton(
                        onPressed: _refusePaper,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                        ),
                        child: Text("Je refuse", style: theme.buttonText),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
