import 'package:flutter/material.dart';
import 'package:shifushotlocal/Pages/friends/friends_page.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // Bouton Profil en haut à droite
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.person,
                        color: theme.textPrimary,
                      ),
                      iconSize: 40.0,
                      onPressed: () {
                        Navigator.pushNamed(context, '/user_profile_page');
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'SHIFUSHOT',
                          style: theme.titleLarge.copyWith(fontSize: 45),
                        ),
                        const SizedBox(height: 20.0),
                        Image.asset(
                          'assets/images/logo.png',
                          width: 230,
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      // Naviguer vers la page Créer une soirée
                      Navigator.pushNamed(context, '/party_screen');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      minimumSize: const Size(300, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Lancer une soirée',
                      style: theme.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/select_game');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'jeux',
                      style: theme.titleMedium.copyWith(
                        color: Colors.white,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              // Alignement des icônes cheers et feedback en bas
              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bouton Feedback (à gauche)
                    GestureDetector(
                      onTap: () {
                        // Action pour le bouton feedback
                        Navigator.pushNamed(context, '/feedback_page');
                      },
                      child: Image.asset(
                        'assets/images/feedback_icon.png',
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Bouton Cheers (à droite)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsPage(),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/cheers.png',
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
