import 'package:flutter/material.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';
import 'dart:math';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/routes.dart';

class PaperGamePlayPage extends StatefulWidget {
  final List<Map<String, dynamic>> papers;
  final List<String> players;
  final List<String> remainingGames;

  const PaperGamePlayPage({
    super.key,
    required this.papers,
    required this.players,
    required this.remainingGames,
  });

  @override
  State<PaperGamePlayPage> createState() => _PaperGamePlayPageState();
}

class _PaperGamePlayPageState extends State<PaperGamePlayPage> {
  int currentPlayerIndex = 0;
  String displayedText = "Appuyez pour tirer un papier";
  bool hasDrawn = false;
  Map<String, dynamic>? selectedPaper;
  Map<String, int> shotCounter = {};
  List<Map<String, dynamic>> remainingPapers = [];

  @override
  void initState() {
    super.initState();
    remainingPapers = List.from(widget.papers); // Copie des papiers
    for (var player in widget.players) {
      shotCounter[player] = 0; // Initialiser les FU à 0
    }
  }

  void _drawPaper() {
    if (remainingPapers.isEmpty) {
      _endGame();
      return;
    }

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
            "$targetPlayer doit boire ${shotCounter[targetPlayer]} FU(s) !",
            style: theme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK",
                  style: theme.buttonText.copyWith(color: theme.primary)),
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

    if (widget.remainingGames.isNotEmpty) {
      final nextRoute = widget.remainingGames.first;

      if (nextRoute == Routes.home) {
        // Fin de la partie : retour à la page d'accueil
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: theme.background,
            title: Text("Fin de la soirée", style: theme.titleMedium),
            content:
                Text("Tous les jeux ont été joués.", style: theme.bodyLarge),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text("Retour à l'accueil",
                    style: theme.buttonText.copyWith(color: theme.primary)),
              ),
            ],
          ),
        );
      } else {
        // Passer au prochain jeu
        Navigator.pushNamed(
          context,
          nextRoute,
          arguments: {
            'players': widget.players,
            'remainingGames': widget.remainingGames.sublist(1),
          },
        );
      }
    } else {
      // Aucun jeu restant, annonce du vainqueur
      final winner =
          shotCounter.entries.reduce((a, b) => a.value < b.value ? a : b).key;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.background,
          title: Text("Fin du jeu", style: theme.titleMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Tous les papiers ont été joués.", style: theme.bodyLarge),
              const SizedBox(height: 20),
              Text("Le gagnant est : $winner !", style: theme.titleMedium),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text("Retour à l'accueil",
                  style: theme.buttonText.copyWith(color: theme.primary)),
            ),
          ],
        ),
      );
    }
  }

  void _showRulesExplanation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Règles du jeu"),
        content: const Text(
          "Chaque joueur peut écrire autant de papiers qu'il le souhaite, contenant des défis ou des actions à réaliser.\n\n"
          "- En fonction du nombre de papiers ajoutés par les joueurs, des papiers mystères créés par l'équipe Shifushot seront ajoutés aléatoirement.\n"
          "- Lors de son tour, un joueur tire un papier au hasard et la cible doit décider s'il accepte ou refuse le défi.\n"
          "- Si le joueur accepte, il réalise l'action écrite sur le papier.\n"
          "- Si le joueur refuse, il doit boire 1 FU (shot) et passer son tour.\n"
          "- Certains papiers peuvent désigner un autre joueur comme cible.\n\n"
          "Le jeu continue jusqu'à ce que tous les papiers aient été joués.\n\n"
          "Attention !!! Prenons un exemple : cible = celui qui pioche   action = fais une bise.\n"
          "On aura donc tour de 'Michel' : fais une bise à 'Michel' et donc c'est impossible.\n"
          "il faudrait changer la cible par un joueur et mettre comme défi : fais une bise à michel\n",
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Compris !"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final currentPlayer = widget.players[currentPlayerIndex];

    return AppShell(
      title: 'Jeu des Papiers',
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline_rounded, color: theme.textPrimary),
          onPressed: _showRulesExplanation,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text('AU TOUR DE',
                style: theme.overline.copyWith(color: theme.textMuted)),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (rect) => theme.brandGradient.createShader(rect),
              child: Text(
                currentPlayer,
                style: theme.displayLarge
                    .copyWith(color: Colors.white, fontSize: 40),
              ),
            ),
            const Spacer(),
            if (hasDrawn)
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -pi / 2,
                    child: Image.asset(
                      'assets/images/papier_dechire.png',
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Cible : ${selectedPaper!['player'] == 'Celui qui piochera' ? currentPlayer : selectedPaper!['player']}",
                          style: theme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayedText,
                          style: theme.bodyLarge
                              .copyWith(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Container(
                width: 220,
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: theme.brandGradient,
                  boxShadow: theme.glowShadow,
                ),
                child: Text('🎲',
                    style: theme.displayLarge.copyWith(fontSize: 80)),
              ),
            const Spacer(),
            if (!hasDrawn)
              GradientButton(
                label: 'Tirer un papier',
                icon: Icons.shuffle_rounded,
                onPressed: _drawPaper,
                height: 64,
              ),
            if (hasDrawn) ...[
              GradientButton(
                label: 'Accepter le défi',
                icon: Icons.check_rounded,
                onPressed: _acceptPaper,
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'Refuser (1 FU)',
                icon: Icons.close_rounded,
                onPressed: _refusePaper,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
