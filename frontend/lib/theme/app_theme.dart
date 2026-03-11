import 'package:flutter/material.dart';

enum AppThemePreset {
  classicLight,
  deepMidnight,
  highContrast,
  emeraldForest,
  cyberpunk,
}

class AppThemeOption {
  final AppThemePreset preset;
  final String label;
  final Color preview;
  final bool forceDark;

  const AppThemeOption({
    required this.preset,
    required this.label,
    required this.preview,
    this.forceDark = false,
  });
}

class AppThemeCatalog {
  static const options = <AppThemeOption>[
    AppThemeOption(
      preset: AppThemePreset.classicLight,
      label: 'Klassisch Hell',
      preview: Color(0xFF1A56DB),
    ),
    AppThemeOption(
      preset: AppThemePreset.deepMidnight,
      label: 'Deep Midnight',
      preview: Color(0xFF7C4DFF),
      forceDark: true,
    ),
    AppThemeOption(
      preset: AppThemePreset.highContrast,
      label: 'Hoher Kontrast',
      preview: Color(0xFFFFD600),
      forceDark: true,
    ),
    AppThemeOption(
      preset: AppThemePreset.emeraldForest,
      label: 'Smaragdwald',
      preview: Color(0xFF2D7D4E),
      forceDark: true,
    ),
    AppThemeOption(
      preset: AppThemePreset.cyberpunk,
      label: 'Cyberpunk',
      preview: Color(0xFFFF007A),
      forceDark: true,
    ),
  ];

  static ThemeData buildTheme(AppThemePreset preset, Brightness brightness) {
    switch (preset) {
      case AppThemePreset.classicLight:
        return _buildClassicLight();
      case AppThemePreset.deepMidnight:
        return _buildDeepMidnight();
      case AppThemePreset.highContrast:
        return _buildHighContrast();
      case AppThemePreset.emeraldForest:
        return _buildEmeraldForest();
      case AppThemePreset.cyberpunk:
        return _buildCyberpunk();
    }
  }

  // ─── 1. Classic Light ────────────────────────────────────────────────────────
  // Professional business look: royal blue, soft grey scaffold, white cards with
  // subtle shadow. Radius 12. Always light mode.
  static ThemeData _buildClassicLight() {
    const primaryColor = Color(0xFF1A56DB);
    const scaffoldColor = Color(0xFFF5F5F7);
    const cardSurface = Colors.white;
    const corner = 12.0;

    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      surface: cardSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: scheme.outlineVariant,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: cardSurface,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(corner + 4),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEEF1F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  // ─── 2. Deep Midnight ────────────────────────────────────────────────────────
  // Modern dark with glassmorphism-inspired styling: deep navy scaffold, violet
  // accent, dark-blue cards with white border. Radius 14. Always dark mode.
  static ThemeData _buildDeepMidnight() {
    const primaryColor = Color(0xFF7C4DFF);
    const scaffoldColor = Color(0xFF121218);
    const cardSurface = Color(0xFF1C1C2E);
    const corner = 14.0;

    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: const Color(0xFF9C7FFF),
      surface: cardSurface,
      surfaceContainer: const Color(0xFF222238),
      surfaceContainerHighest: const Color(0xFF2C2C44),
      onSurfaceVariant: const Color(0xFFBBBBDD),
      outline: Colors.white.withValues(alpha: 0.15),
      outlineVariant: Colors.white.withValues(alpha: 0.08),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: Colors.white.withValues(alpha: 0.1),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: cardSurface,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(corner + 4),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2C2C44),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  // ─── 3. High Contrast ────────────────────────────────────────────────────────
  // Accessibility-first: pure black scaffold, signal-yellow accent, 2px solid
  // borders everywhere, no decorative shadows. Radius 8. Always dark mode.
  static ThemeData _buildHighContrast() {
    const accentColor = Color(0xFFFFD600);
    const scaffoldColor = Color(0xFF000000);
    const cardSurface = Color(0xFF0A0A0A);
    const corner = 8.0;
    const borderWidth = 2.0;

    final scheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accentColor,
      onPrimary: Colors.black,
      secondary: accentColor,
      onSecondary: Colors.black,
      tertiary: Colors.white,
      surface: cardSurface,
      surfaceContainer: const Color(0xFF111111),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
      onSurface: Colors.white,
      onSurfaceVariant: Colors.white.withValues(alpha: 0.85),
      outline: accentColor,
      outlineVariant: Colors.white.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: accentColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
      cardColor: cardSurface,
      cardTheme: const CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(corner)),
          side: BorderSide(color: accentColor, width: borderWidth),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111111),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(corner)),
          borderSide: BorderSide(color: accentColor, width: borderWidth),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(corner)),
          borderSide: BorderSide(color: Colors.white, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(corner)),
          borderSide: BorderSide(color: accentColor, width: borderWidth),
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(corner)),
            side: BorderSide(color: Colors.white, width: 1.5),
          ),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(corner))),
          side: const BorderSide(color: accentColor, width: borderWidth),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(corner))),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1A1A1A),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }

  // ─── 4. Emerald Forest ───────────────────────────────────────────────────────
  // Nature-inspired: dark forest-green scaffold, sage-green cards, gold accent.
  // Organic large radius (24). Always dark mode.
  static ThemeData _buildEmeraldForest() {
    const accentColor = Color(0xFFFFC107);
    const scaffoldColor = Color(0xFF0A2416);
    const cardSurface = Color(0xFF163D28);
    const corner = 24.0;

    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D6A4F),
      brightness: Brightness.dark,
    ).copyWith(
      primary: accentColor,
      onPrimary: Colors.black,
      secondary: const Color(0xFF52B788),
      onSecondary: Colors.black,
      tertiary: const Color(0xFF74C69D),
      surface: cardSurface,
      surfaceContainer: const Color(0xFF1E4A35),
      surfaceContainerHighest: const Color(0xFF265040),
      onSurface: const Color(0xFFE8F5E9),
      onSurfaceVariant: const Color(0xFFA5D6A7),
      outline: const Color(0xFF52B788).withValues(alpha: 0.35),
      outlineVariant: const Color(0xFF52B788).withValues(alpha: 0.2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: const Color(0xFF52B788).withValues(alpha: 0.2),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColor,
        foregroundColor: Color(0xFFE8F5E9),
        elevation: 0,
      ),
      cardColor: cardSurface,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(corner),
          side: BorderSide(color: const Color(0xFF52B788).withValues(alpha: 0.3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E4A35),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner - 8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner - 8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(corner - 8),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner - 4)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner - 4)),
          side: BorderSide(color: accentColor.withValues(alpha: 0.7)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(corner - 4)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E4A35),
        contentTextStyle: TextStyle(color: Color(0xFFE8F5E9)),
      ),
    );
  }

  // ─── 5. Cyberpunk ────────────────────────────────────────────────────────────
  // Experimental neon: deep-violet scaffold, neon-pink primary, cyan secondary.
  // Sharp Radius 0, neon glow via elevated card shadows. Always dark mode.
  static ThemeData _buildCyberpunk() {
    const neonPink = Color(0xFFFF007A);
    const neonCyan = Color(0xFF00E5FF);
    const scaffoldColor = Color(0xFF0D0020);
    const cardSurface = Color(0xFF1A0030);

    final scheme = ColorScheme.fromSeed(
      seedColor: neonPink,
      brightness: Brightness.dark,
    ).copyWith(
      primary: neonPink,
      onPrimary: Colors.white,
      secondary: neonCyan,
      onSecondary: Colors.black,
      tertiary: const Color(0xFFFF79C6),
      surface: cardSurface,
      surfaceContainer: const Color(0xFF200040),
      surfaceContainerHighest: const Color(0xFF2D0060),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFFCC99BB),
      outline: neonPink.withValues(alpha: 0.6),
      outlineVariant: neonPink.withValues(alpha: 0.25),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldColor,
      dividerColor: neonPink.withValues(alpha: 0.4),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: cardSurface,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 8,
        shadowColor: neonPink.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: neonPink),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(color: neonPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: neonPink.withValues(alpha: 0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: neonCyan, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPink,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          elevation: 6,
          shadowColor: neonPink.withValues(alpha: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonCyan,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: const BorderSide(color: neonCyan, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonPink,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF200040),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
