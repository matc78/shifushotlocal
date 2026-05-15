import 'package:flutter/material.dart';
import 'package:shifushotlocal/routes.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

class FollowLineModeSelector extends StatelessWidget {
  const FollowLineModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Suis la ligne',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSection(
              title: 'MODE RAPIDITÉ',
              subtitle: 'Le plus rapide gagne',
              theme: theme,
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Facile',
              icon: Icons.bolt_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.followLineSpeedEasy),
            ),
            const SizedBox(height: 10),
            const GhostButton(
              label: 'Compliqué — bientôt',
              icon: Icons.lock_outline_rounded,
              onPressed: null,
            ),
            const SizedBox(height: 10),
            const GhostButton(
              label: 'Très dur — bientôt',
              icon: Icons.lock_outline_rounded,
              onPressed: null,
            ),
            const SizedBox(height: 32),
            _ModeSection(
              title: 'MODE PRÉCISION',
              subtitle: 'La main la plus stable',
              theme: theme,
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: 'Facile',
              icon: Icons.gps_fixed_rounded,
              onPressed: () =>
                  Navigator.pushNamed(context, Routes.followLinePrecisionEasy),
            ),
            const SizedBox(height: 10),
            const GhostButton(
              label: 'Compliqué — bientôt',
              icon: Icons.lock_outline_rounded,
              onPressed: null,
            ),
            const SizedBox(height: 10),
            const GhostButton(
              label: 'Très dur — bientôt',
              icon: Icons.lock_outline_rounded,
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  const _ModeSection({
    required this.title,
    required this.subtitle,
    required this.theme,
  });
  final String title;
  final String subtitle;
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: theme.brandGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: theme.overline.copyWith(
                  color: theme.textPrimary,
                  fontSize: 13,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 2),
            Text(subtitle, style: theme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
