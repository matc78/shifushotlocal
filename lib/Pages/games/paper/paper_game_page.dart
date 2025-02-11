import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/Pages/games/paper/paper_game_play_page.dart';

class PaperGamePage extends StatefulWidget {
  final List<String> players;
  final List<String> remainingGames;

  const PaperGamePage({
    Key? key,
    required this.players,
    this.remainingGames = const [], // Liste vide par défaut
  }) : super(key: key);

  @override
  _PaperGamePageState createState() => _PaperGamePageState();
}

class _PaperGamePageState extends State<PaperGamePage> {
  final List<Map<String, dynamic>> papers = [];
  final TextEditingController paperController = TextEditingController();
  String? selectedPlayer;

  @override
  void dispose() {
    paperController.dispose();
    super.dispose();
  }

  void _addPaper() {
    if (selectedPlayer != null && paperController.text.trim().isNotEmpty) {
      setState(() {
        papers.add({
          'player': selectedPlayer,
          'text': paperController.text.trim(),
        });
        paperController.clear();
      });
    }
  }

  void _startGame() {
    if (papers.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaperGamePlayPage(
            papers: papers,
            players: widget.players,
            remainingGames: widget.remainingGames, // Passer les jeux restants
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoutez au moins un papier avant de commencer le jeu !")),
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

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text("Jeu des Papiers", style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: theme.primary),
            onPressed: _showRulesExplanation,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedPlayer,
              decoration: InputDecoration(
                labelText: 'Choisir la cible du défi',
                labelStyle: TextStyle(color: theme.textPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
              items: widget.players
                  .map((player) => DropdownMenuItem(
                        value: player,
                        child: Text(player, style: theme.bodyLarge),
                      ))
                  .toList()
                ..add(DropdownMenuItem(
                  value: 'Celui qui piochera',
                  child: Text('Celui qui piochera', style: theme.bodyLarge),
                )),
              onChanged: (value) {
                setState(() {
                  selectedPlayer = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: paperController,
              decoration: InputDecoration(
                labelText: 'Écrire une vérité ou une action',
                labelStyle: TextStyle(color: theme.textPrimary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary),
                ),
              ),
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addPaper,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Ajouter le papier", style: theme.buttonText),
            ),
            const SizedBox(height: 16),
            Text(
              "Nombre de papiers ajoutés : ${papers.length}",
              style: theme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 250,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Commencer le jeu",
                    style: theme.buttonText.copyWith(fontSize: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
