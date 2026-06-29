import 'package:flutter/material.dart';

// ── Voldog-inspired design tokens ──────────────────────────────────
const Color brandPrimary = Color(0xFF204E4A);   // Deep forest green
const Color accentGreen = Color(0xFF6FDA44);    // Vibrant green highlights
const Color accentCoral = Color(0xFFEC7357);    // Active / hover states
const Color accentYellow = Color(0xFFE1E53F);   // Stars / badges
const Color warmCream = Color(0xFFF4F1EB);      // Page background (not stark white)

const double radiusSm = 8;
const double radiusMd = 14;
const double radiusLg = 20;
const double radiusXl = 100; // pill-shaped

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.light,
  );

  // Warm up the surface slightly so cards sit on cream, not pure white.
  final warmScheme = scheme.copyWith(
    surface: warmCream,
    surfaceContainerHighest: warmCream,
    surfaceContainerLow: Colors.white,
  );

  return _buildTheme(warmScheme, Brightness.light);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPrimary,
    brightness: Brightness.dark,
  );
  return _buildTheme(scheme, Brightness.dark);
}

ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
  final isLight = brightness == Brightness.light;

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: isLight ? warmCream : null,

    // ── AppBar ──
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    // ── Cards ──
    cardTheme: CardThemeData(
      color: isLight ? Colors.white : null,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: isLight
            ? BorderSide(color: scheme.outlineVariant.withAlpha(50))
            : BorderSide.none,
      ),
      shadowColor: Colors.black.withAlpha(8),
    ),

    // ── Input fields ──
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(60)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(60)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Buttons ──
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        side: BorderSide(color: scheme.outline.withAlpha(120)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    // ── Chips / Filters ──
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXl),
      ),
      side: BorderSide(color: scheme.outlineVariant.withAlpha(80)),
      backgroundColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
      selectedColor: scheme.primary.withAlpha(25),
      labelStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    // ── Bottom Navigation ──
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // ── Navigation Rail ──
    navigationRailTheme: NavigationRailThemeData(
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // ── Dialogs ──
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
      ),
    ),

    // ── Snackbar / Toast ──
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
    ),

    // ── Divider ──
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withAlpha(60),
      thickness: 0.5,
      space: 1,
    ),
  );
}
