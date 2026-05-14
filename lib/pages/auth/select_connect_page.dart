import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'connexion_page.dart';

class SelectConnectPage extends StatelessWidget {
  const SelectConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      body: PartyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: theme.textPrimary),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'BIENVENUE',
                  style: theme.overline.copyWith(color: theme.secondary),
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (rect) =>
                      theme.brandGradient.createShader(rect),
                  child: Text(
                    'SHIFUSHOT',
                    style:
                        theme.displayLarge.copyWith(color: Colors.white, fontSize: 48),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: theme.glowShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 213,
                      height: 103,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                GradientButton(
                  label: 'Connexion',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnexionPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                GhostButton(
                  label: 'Créer un compte',
                  icon: Icons.person_add_alt_rounded,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/createAccount'),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
