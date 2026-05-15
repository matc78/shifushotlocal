import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';
import 'package:shifushotlocal/widgets/app_shell.dart';

import 'sound_board_page.dart';

class SoundCategorySelectionPage extends StatelessWidget {
  SoundCategorySelectionPage({super.key});

  final Map<String, List<String>> categories = {
    'Pet': [
      'assets/audios/pet/pet1.mp3',
      'assets/audios/pet/pet2.mp3',
      'assets/audios/pet/pet3.mp3',
      'assets/audios/pet/pet4.mp3',
      'assets/audios/pet/petponey1.mp3',
    ],
    'Pet Crosnier': [
      'assets/audios/pet_crosnier/PetCrosnier1.mp3',
      'assets/audios/pet_crosnier/PetCrosnier2.mp3',
      'assets/audios/pet_crosnier/PetCrosnier3.mp3',
      'assets/audios/pet_crosnier/PetCrosnier4.mp3',
      'assets/audios/pet_crosnier/PetCrosnier5.mp3',
      'assets/audios/pet_crosnier/PetCrosnier6.mp3',
      'assets/audios/pet_crosnier/PetCrosnier7.mp3',
      'assets/audios/pet_crosnier/PetCrosnier8.mp3',
      'assets/audios/pet_crosnier/PetCrosnier9.mp3',
      'assets/audios/pet_crosnier/PetCrosnier10.mp3',
      'assets/audios/pet_crosnier/PetCrosnier11.mp3',
      'assets/audios/pet_crosnier/PetCrosnier12.mp3',
      'assets/audios/pet_crosnier/PetCrosnier13.mp3',
      'assets/audios/pet_crosnier/PetCrosnier14.mp3',
      'assets/audios/pet_crosnier/PetCrosnier15.mp3',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return AppShell(
      title: 'Sonothèque',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final name = categories.keys.elementAt(i);
            return Material(
              color: theme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SoundBoardPage(
                      categoryName: name,
                      sounds: categories[name]!,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: theme.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.volume_up_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(name,
                            style: theme.bodyLarge.copyWith(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            )),
                      ),
                      Icon(Icons.chevron_right_rounded, color: theme.textMuted),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
