import 'package:flutter/material.dart';

class AppTheme {
  static LightModeTheme of(BuildContext context) {
    return LightModeTheme();
  }

  // Couleurs principales
  late Color primary;
  late Color secondary;
  late Color background;
  late Color textPrimary;
  late Color textSecondary;
  late Color buttonColor;

  // Styles de texte
  late TextStyle titleLarge;
  late TextStyle titleMedium;
  late TextStyle bodyLarge;
  late TextStyle bodyMedium;
  late TextStyle buttonText;
}

class LightModeTheme extends AppTheme {
  LightModeTheme() {
    // Définition des couleurs
    primary = const Color(0xFF000000); // Noir
    secondary = const Color(0xFFBC002D); // Rouge
    background = const Color(0xFFFAEADC); // Beige clair
    textPrimary = const Color(0xFF14181B); // Texte principal
    textSecondary = const Color(0xFF262626); // Texte secondaire
    buttonColor = const Color(0xFF000000); // Bouton noir

    // Styles de texte
    titleLarge = TextStyle(
      fontFamily: 'jaro',
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    );
    titleMedium =  TextStyle(
      fontFamily: 'jaro',
      fontSize: 24,
      fontWeight: FontWeight.normal,
      color: textPrimary,
    );
    bodyLarge =  TextStyle(
      fontFamily: 'afacad',
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textPrimary,
    );
    bodyMedium =  TextStyle(
      fontFamily: 'afacad',
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textPrimary,
    );
    buttonText =  const TextStyle(
      fontFamily: 'afacad',
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
  }
}
