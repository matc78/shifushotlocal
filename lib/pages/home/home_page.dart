import 'package:flutter/material.dart';
import 'package:shifushotlocal/pages/auth/guest_prompt.dart';
import 'package:shifushotlocal/state/guest_session.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isGuest = GuestSession.instance.isGuest;

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
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        isGuest ? Icons.person_outline : Icons.person,
                        color: theme.textPrimary,
                      ),
                      iconSize: 40.0,
                      onPressed: () {
                        if (isGuest) {
                          promptToSignUp(
                            context,
                            reason:
                                'Crée un compte pour personnaliser ton profil et garder tes stats.',
                          );
                        } else {
                          Navigator.pushNamed(context, '/user_profile_page');
                        }
                      },
                    ),
                  ),
                  if (isGuest) _GuestBanner(theme: theme),
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
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      minimumSize: const Size(300, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Soon !',
                      style: theme.titleMedium.copyWith(
                        color: theme.secondary,
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/select_game'),
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
              Positioned(
                bottom: 16.0,
                left: 16.0,
                right: 16.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/feedback_page'),
                      child: Image.asset(
                        'assets/images/feedback_icon.png',
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.contain,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isGuest) {
                          promptToSignUp(
                            context,
                            reason:
                                "La liste d'amis n'est disponible qu'avec un compte.",
                          );
                          return;
                        }
                        Navigator.pushNamed(context, '/friends');
                      },
                      child: Opacity(
                        opacity: isGuest ? 0.4 : 1.0,
                        child: Image.asset(
                          'assets/images/cheers.png',
                          width: 50.0,
                          height: 50.0,
                          fit: BoxFit.contain,
                        ),
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

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.theme});
  final AppTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.buttonColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.buttonColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.buttonColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode invité — jeux locaux uniquement',
              style: theme.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => promptToSignUp(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Créer un compte',
              style: theme.bodyMedium.copyWith(
                color: theme.buttonColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
