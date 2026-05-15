import 'package:flutter/material.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'select_connect_page.dart';
import 'package:shifushotlocal/routes.dart';

class DebutPage extends StatelessWidget {
  const DebutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      body: PartyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  'PARTY ON.',
                  textAlign: TextAlign.center,
                  style: theme.overline.copyWith(color: theme.textMuted),
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (rect) =>
                      theme.brandGradient.createShader(rect),
                  child: Text(
                    'SHIFUSHOT',
                    style: theme.displayLarge.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Le party game N°1\nentre potes.",
                  textAlign: TextAlign.center,
                  style: theme.bodyLarge.copyWith(
                    fontSize: 18,
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: theme.glowShadow,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 180,
                    width: 280,
                    fit: BoxFit.contain,
                  ),
                ),
                const Spacer(),
                GradientButton(
                  label: "C'est parti !",
                  icon: Icons.local_fire_department_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectConnectPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                GhostButton(
                  label: 'Jouer sans compte',
                  icon: Icons.bolt_rounded,
                  onPressed: () {
                    GuestSession.instance.enterGuestMode();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.home,
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'En invité : jeux locaux uniquement.\nCrée un compte pour les amis & le jeu en ligne.',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: theme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
