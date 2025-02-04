import 'package:flutter/material.dart';
import 'package:shifushotlocal/friends_page.dart';
import 'app_theme.dart';

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
          child: Column(
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
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
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
                    width: 60.0,
                    height: 60.0,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
