import 'package:flutter/material.dart';
import 'package:shifushotlocal/pages/games/local/paper/paper_game_play_page.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class PaperGamePage extends StatefulWidget {
  const PaperGamePage({
    super.key,
    required this.players,
    this.remainingGames = const [],
  });
  final List<String> players;
  final List<String> remainingGames;

  @override
  State<PaperGamePage> createState() => _PaperGamePageState();
}

class _PaperGamePageState extends State<PaperGamePage> {
  final List<Map<String, dynamic>> _papers = [];
  final TextEditingController _controller = TextEditingController();
  String? _selectedPlayer;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addPaper() {
    final text = _controller.text.trim();
    if (_selectedPlayer == null || text.isEmpty) return;
    setState(() {
      _papers.add({'player': _selectedPlayer, 'text': text});
      _controller.clear();
    });
  }

  void _start() {
    if (_papers.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Ajoute au moins un papier pour commencer.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaperGamePlayPage(
          papers: _papers,
          players: widget.players,
          remainingGames: widget.remainingGames,
        ),
      ),
    );
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Règles du jeu'),
        content: const Text(
          "Chaque joueur écrit autant de papiers qu'il veut (défis, actions).\n\n"
          "À son tour, un joueur tire au hasard et la cible accepte ou boit un FU.\n\n"
          "Astuce : si la cible = celui qui pioche, ça peut tomber sur l'auteur.",
          textAlign: TextAlign.justify,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Compris !')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Jeu des Papiers',
      actions: [
        IconButton(
          icon: Icon(Icons.help_outline_rounded, color: theme.textPrimary),
          onPressed: _showRules,
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedPlayer,
              dropdownColor: theme.surface,
              style: theme.bodyLarge,
              decoration: const InputDecoration(hintText: 'Cible du défi'),
              items: [
                ...widget.players.map(
                  (p) => DropdownMenuItem(value: p, child: Text(p)),
                ),
                const DropdownMenuItem(
                  value: 'Celui qui piochera',
                  child: Text('Celui qui piochera'),
                ),
              ],
              onChanged: (v) => setState(() => _selectedPlayer = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              style: theme.bodyLarge,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Une action, une vérité…'),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Ajouter le papier',
              icon: Icons.add_rounded,
              onPressed: _addPaper,
            ),
            const SizedBox(height: 16),
            SectionCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: theme.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${_papers.length}',
                        style: theme.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Papiers ajoutés', style: theme.bodyLarge),
                        const SizedBox(height: 2),
                        Text(
                          _papers.isEmpty
                              ? 'Ajoute-en au moins un pour commencer'
                              : 'Prêt à lancer',
                          style: theme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GradientButton(
              label: 'Commencer le jeu',
              icon: Icons.play_arrow_rounded,
              onPressed: _start,
              height: 60,
            ),
          ],
        ),
      ),
    );
  }
}
