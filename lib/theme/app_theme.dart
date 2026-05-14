import 'package:flutter/material.dart';

class AppTheme {
  static AppTheme of(BuildContext context) => _dark;
  static final AppTheme _dark = AppTheme._();

  AppTheme._();

  // ---------- Palette ----------
  final Color background = const Color(0xFF0E0B1F); // near-black violet
  final Color backgroundAlt = const Color(0xFF14102B);
  final Color surface = const Color(0xFF1E1A38);
  final Color surfaceAlt = const Color(0xFF2A2447);
  final Color border = const Color(0xFF3A3262);

  // Brand accents (vivid party gradient)
  final Color primary = const Color(0xFFFF3DAA); // hot pink
  final Color primaryDeep = const Color(0xFF9747FF); // electric violet
  final Color secondary = const Color(0xFFE7FF3F); // acid lime
  final Color warning = const Color(0xFFFF8A3D); // warm orange

  // Text
  final Color textPrimary = const Color(0xFFFFFFFF);
  final Color textSecondary = const Color(0xFFB8B5D9);
  final Color textMuted = const Color(0xFF7F7AA5);

  // Legacy aliases (kept for back-compat with existing widgets)
  Color get buttonColor => primary;

  // ---------- Gradients ----------
  LinearGradient get brandGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF3DAA), Color(0xFF9747FF)],
      );

  LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A0F36), Color(0xFF0E0B1F)],
      );

  RadialGradient get heroGlow => const RadialGradient(
        center: Alignment.topCenter,
        radius: 1.1,
        colors: [Color(0x66FF3DAA), Color(0x00FF3DAA)],
      );

  // ---------- Radii / shadows ----------
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusPill = 999.0;

  List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, 8),
        ),
      ];

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ---------- Typography ----------
  TextStyle get displayLarge => TextStyle(
        fontFamily: 'jaro',
        fontSize: 56,
        fontWeight: FontWeight.w900,
        height: 0.95,
        letterSpacing: 1.5,
        color: textPrimary,
      );

  TextStyle get titleLarge => TextStyle(
        fontFamily: 'jaro',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  TextStyle get titleMedium => TextStyle(
        fontFamily: 'jaro',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  TextStyle get bodyLarge => TextStyle(
        fontFamily: 'afacad',
        fontSize: 16,
        color: textPrimary,
      );

  TextStyle get bodyMedium => TextStyle(
        fontFamily: 'afacad',
        fontSize: 14,
        color: textSecondary,
      );

  TextStyle get buttonText => const TextStyle(
        fontFamily: 'afacad',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: Colors.white,
      );

  TextStyle get overline => TextStyle(
        fontFamily: 'afacad',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
        color: textMuted,
      );

  // ---------- MaterialApp ThemeData ----------
  static ThemeData materialTheme() {
    final t = _dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: t.background,
      colorScheme: ColorScheme.dark(
        surface: t.surface,
        primary: t.primary,
        secondary: t.secondary,
        onPrimary: Colors.white,
        onSurface: t.textPrimary,
      ),
      fontFamily: 'afacad',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: t.textPrimary),
        titleTextStyle: t.titleMedium,
      ),
      textTheme: TextTheme(
        displayLarge: t.displayLarge,
        titleLarge: t.titleLarge,
        titleMedium: t.titleMedium,
        bodyLarge: t.bodyLarge,
        bodyMedium: t.bodyMedium,
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: Colors.white,
          textStyle: t.buttonText,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.textPrimary,
          textStyle: t.buttonText,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        hintStyle: t.bodyMedium.copyWith(color: t.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: t.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: t.primary, width: 1.5),
        ),
      ),
      iconTheme: IconThemeData(color: t.textPrimary),
      dividerColor: t.border,
    );
  }
}

/// Gradient primary CTA used everywhere.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final disabled = onPressed == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: SizedBox(
        width: expanded ? double.infinity : null,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: theme.brandGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            boxShadow: disabled ? null : theme.glowShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                    ],
                    Text(label, style: theme.buttonText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ghost / outlined button used as secondary CTA.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return SizedBox(
      width: expanded ? double.infinity : null,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.textPrimary,
          side: BorderSide(color: theme.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.textPrimary, size: 20),
              const SizedBox(width: 10),
            ],
            Text(label, style: theme.buttonText),
          ],
        ),
      ),
    );
  }
}

/// Animated party-style background gradient.
class PartyBackground extends StatelessWidget {
  const PartyBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: theme.backgroundGradient),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(
              color: theme.primary.withValues(alpha: 0.35),
              size: 320,
            ),
          ),
          Positioned(
            top: 80,
            right: -100,
            child: _Blob(
              color: theme.primaryDeep.withValues(alpha: 0.30),
              size: 280,
            ),
          ),
          Positioned(
            bottom: -140,
            left: -60,
            child: _Blob(
              color: theme.primaryDeep.withValues(alpha: 0.25),
              size: 360,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
