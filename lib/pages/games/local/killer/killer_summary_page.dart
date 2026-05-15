import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class KillerSummaryPage extends StatefulWidget {
  const KillerSummaryPage({super.key, required this.playerData});
  final Map<String, dynamic> playerData;

  @override
  State<KillerSummaryPage> createState() => _KillerSummaryPageState();
}

class _KillerSummaryPageState extends State<KillerSummaryPage> {
  late Map<String, dynamic> _playerData;
  late List<String> _sorted;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _playerData = Map<String, dynamic>.from(widget.playerData);
    _sortPlayers();
    _checkGameOver();
  }

  void _sortPlayers() => _sorted = _playerData.keys.toList()..sort();

  void _checkGameOver() {
    setState(() {
      _isGameOver = _playerData.values.where((p) => !p['isDead']).length <= 1;
    });
  }

  void _restart() => Navigator.pushReplacementNamed(context, Routes.killer);

  void _showAction(String player) {
    final theme = AppTheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Détails de l'action", style: theme.titleMedium),
        content: Text(
          '$player doit :\n\nAction : ${_playerData[player]['action']}\nCible : ${_playerData[player]['target']}',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _markDead(String player) {
    setState(() {
      final killer = _playerData.keys.firstWhere(
        (n) => _playerData[n]['target'] == player,
        orElse: () => '',
      );
      _playerData[killer]['target'] = _playerData[player]['target'];
      _playerData[killer]['action'] = _playerData[player]['action'];
      _playerData[player]['isDead'] = true;
      _checkGameOver();
      _sortPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (_isGameOver) {
      final winner = _playerData.keys
          .firstWhere((n) => !_playerData[n]['isDead'], orElse: () => '—');
      return AppShell(
        title: 'Fin de partie',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              const Spacer(),
              Text('🏆', style: theme.displayLarge.copyWith(fontSize: 96)),
              const SizedBox(height: 12),
              Text('GAGNANT',
                  style: theme.overline.copyWith(color: theme.textMuted)),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (rect) =>
                    theme.brandGradient.createShader(rect),
                child: Text(winner,
                    style: theme.displayLarge
                        .copyWith(color: Colors.white, fontSize: 48)),
              ),
              const Spacer(),
              GradientButton(
                label: 'Recommencer',
                icon: Icons.refresh_rounded,
                onPressed: _restart,
              ),
            ],
          ),
        ),
      );
    }

    return AppShell(
      title: 'Résumé du jeu',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final name = _sorted[i];
                  final player = _playerData[name];
                  final dead = player['isDead'] as bool;
                  return Opacity(
                    opacity: dead ? 0.5 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: dead ? null : theme.brandGradient,
                              color: dead ? theme.surfaceAlt : null,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: theme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(name,
                                    style: theme.bodyLarge.copyWith(
                                      decoration: dead
                                          ? TextDecoration.lineThrough
                                          : null,
                                    )),
                                if (dead)
                                  Text('Éliminé', style: theme.bodyMedium),
                              ],
                            ),
                          ),
                          if (!dead) ...[
                            IconButton(
                              icon: Icon(Icons.info_outline_rounded,
                                  color: theme.textMuted),
                              onPressed: () => _showAction(name),
                            ),
                            IconButton(
                              icon: const FaIcon(
                                FontAwesomeIcons.skullCrossbones,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => _markDead(name),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            GhostButton(
              label: 'Recommencer la partie',
              icon: Icons.refresh_rounded,
              onPressed: _restart,
            ),
          ],
        ),
      ),
    );
  }
}
