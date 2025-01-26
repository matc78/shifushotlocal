import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'select_connect_page.dart';


class DebutPage extends StatelessWidget {
  const DebutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              'SHIFUSHOT',
              style: theme.titleLarge.copyWith(fontSize: 40),
            ),
            const SizedBox(height: 50),

            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 150, // Ajustez la hauteur
              width: 300, // Limitez la largeur 
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 200), // Espacement entre le logo et le titre

            // Bouton
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  // Navigation vers SelectConnectPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectConnectPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.buttonColor, // Couleur de fond du bouton
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // Bords arrondis
                  ),
                ),
                child: Text(
                  'C\'est parti !',
                  style: theme.buttonText,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
