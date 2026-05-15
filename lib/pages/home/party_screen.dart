import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class PartyScreen extends StatefulWidget {
  const PartyScreen({super.key});

  @override
  State<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends State<PartyScreen> {
  static const _moods = <_MoodOption>[
    _MoodOption('Hardcore', Icons.local_fire_department_rounded,
        'Ambiance intense, faut suivre'),
    _MoodOption('Chill', Icons.weekend_rounded, 'Soirée tranquille entre potes'),
    _MoodOption('Découverte', Icons.explore_rounded,
        'Pour ceux qui connaissent pas encore'),
  ];

  String _selectedMood = 'Chill';
  final List<String> _games = [
    Routes.paperGame,
    Routes.diceGame,
    Routes.clockGame,
  ];

  void _startParty() {
    final shuffled = [..._games]..shuffle();
    Navigator.pushNamed(
      context,
      Routes.lobbyScreen,
      arguments: {
        'mode': 'Soirée',
        'selectedGames': shuffled,
        'mood': _selectedMood,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Créer une soirée',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('CHOISIS LE MOOD',
                style: theme.overline
                    .copyWith(color: theme.textPrimary, fontSize: 13)),
            const SizedBox(height: 12),
            ..._moods.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MoodTile(
                    option: m,
                    selected: m.label == _selectedMood,
                    onTap: () => setState(() => _selectedMood = m.label),
                  ),
                )),
            const Spacer(),
            GradientButton(
              label: 'Démarrer la soirée',
              icon: Icons.celebration_rounded,
              onPressed: _startParty,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodOption {
  const _MoodOption(this.label, this.icon, this.subtitle);
  final String label;
  final IconData icon;
  final String subtitle;
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _MoodOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Material(
      color: theme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: selected ? theme.primary : theme.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? theme.brandGradient : null,
                  color: selected ? null : theme.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon,
                    color: selected ? Colors.white : theme.textMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.label,
                        style: theme.bodyLarge.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w800,
                        )),
                    const SizedBox(height: 2),
                    Text(option.subtitle, style: theme.bodyMedium),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: theme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
