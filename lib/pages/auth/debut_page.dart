import 'package:flutter/material.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'select_connect_page.dart';

class DebutPage extends StatelessWidget {
  const DebutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SHIFUSHOT',
                  style: theme.titleLarge.copyWith(fontSize: 40),
                ),
                const SizedBox(height: 50),
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 300,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 120),
                SizedBox(
                  width: 400,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SelectConnectPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("C'est parti !", style: theme.buttonText),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: TextButton(
                    onPressed: () {
                      GuestSession.instance.enterGuestMode();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/homepage',
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: theme.buttonColor, width: 1.5),
                      ),
                    ),
                    child: Text(
                      'Jouer sans compte',
                      style: theme.buttonText.copyWith(color: theme.buttonColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'En invité : jeux locaux uniquement.\nCrée un compte pour accéder aux amis et au jeu en ligne.',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 12,
                    color: theme.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
