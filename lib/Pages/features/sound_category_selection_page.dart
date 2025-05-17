import 'package:flutter/material.dart';
import 'sound_board_page.dart';
import '../../../theme/app_theme.dart';

class SoundCategorySelectionPage extends StatelessWidget {
  final Map<String, List<String>> categories = {
    'Pet': [
      'assets/audios/pet/pet1.mp3',
      'assets/audios/pet/pet2.mp3',
      'assets/audios/pet/pet3.mp3',
      'assets/audios/pet/pet4.mp3',
      'assets/audios/pet/petponey1.mp3',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Choisis une catégorie', style: theme.titleMedium),
        centerTitle: true,
        backgroundColor: theme.background,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories.keys.elementAt(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Image.network(
                'https://img.icons8.com/?size=100&id=FaFhLHDGUZAA&format=png&color=000000',
                width: 32,
                height: 32,
                color: theme.textSecondary, // facultatif si tu veux le teinter
                errorBuilder: (context, error, stackTrace) => Icon(Icons.error, color: theme.textSecondary),
              ),
              title: Text(category, style: theme.titleMedium),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SoundBoardPage(
                      categoryName: category,
                      sounds: categories[category]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
