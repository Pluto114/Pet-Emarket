import 'package:flutter/material.dart';

const Color voldogOrange = Color(0xFFFF8C42);
const double radiusCard = 24.0;

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: voldogOrange, brightness: Brightness.light);
  final warm = scheme.copyWith(
    surface: const Color(0xFFFFF8F3),
    surfaceContainerLow: const Color(0xFFFFF1E8),
    surfaceContainer: const Color(0xFFFFECD8),
    surfaceContainerHigh: const Color(0xFFFFE4CC),
  );
  return _build(warm, Brightness.light);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: voldogOrange, brightness: Brightness.dark);
  final warm = scheme.copyWith(
    surface: const Color(0xFF1E1510),
    surfaceContainerLow: const Color(0xFF281D16),
    surfaceContainer: const Color(0xFF32251C),
    surfaceContainerHigh: const Color(0xFF3C2D22),
  );
  return _build(warm, Brightness.dark);
}

ThemeData _build(ColorScheme scheme, Brightness brightness) {
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(80))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(80))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: scheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    )),

    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    )),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      backgroundColor: scheme.surfaceContainerLow,
      labelStyle: TextStyle(fontSize: 13, color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 0, surfaceTintColor: Colors.transparent,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    navigationRailTheme: NavigationRailThemeData(
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard))),

    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),

    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withAlpha(60), thickness: 0.5, space: 1),
  );
}
