import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'connexion_page.dart';

class SelectConnectPage extends StatelessWidget {
  const SelectConnectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(flex: 2),
              // Titre
              Text(
                'SHIFUSHOT',
                style: theme.titleLarge.copyWith(fontSize: 40),
              ),
              const SizedBox(height: 16.0),
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 213.0,
                  height: 103.0,
                  fit: BoxFit.contain,
                ),
              ),
              const Spacer(flex: 4),
              // Bouton Connexion
              SizedBox(
                width: 370.0,
                height: 54.0,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConnexionPage(), // Redirection vers ConnexionPage
                      ),
                    );// Redirection vers la page Connexion
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: Text(
                    'Connexion',
                    style: theme.buttonText.copyWith(color: theme.background),
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              // Divider
              SizedBox(
                width: 200.0,
                child: Divider(
                  thickness: 1.0,
                  color: theme.primary,
                ),
              ),
              const SizedBox(height: 20.0),
              // Bouton Créer un compte
              SizedBox(
                width: 190.0,
                height: 40.0,
                child: ElevatedButton(
                  onPressed: () {
                    // Redirection vers la page Créer un compte
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  child: Text(
                    'Créer un compte',
                    style: theme.buttonText.copyWith(color: theme.background),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
