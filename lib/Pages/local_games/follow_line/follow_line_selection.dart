import 'package:flutter/material.dart';
import 'package:shifushotlocal/theme/app_theme.dart';

class FollowLineModeSelector extends StatelessWidget {
  const FollowLineModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Suivre la ligne', style: theme.titleMedium),
        backgroundColor: theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mode Rapidité', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/follow_line_speed_easy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Facile', style: theme.buttonText),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: null, // pas encore implémenté
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Compliqué (bientôt)', style: theme.bodyMedium.copyWith(color: Colors.red)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Très dur (bientôt)', style: theme.bodyMedium.copyWith(color: Colors.red)),
            ),
            const SizedBox(height: 40),
            Text('Mode Précision', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/follow_line_precision_easy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.buttonColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Facile', style: theme.buttonText),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: null, // pas encore implémenté
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Compliqué (bientôt)', style: theme.bodyMedium.copyWith(color: Colors.red)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Très dur (bientôt)', style: theme.bodyMedium.copyWith(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
