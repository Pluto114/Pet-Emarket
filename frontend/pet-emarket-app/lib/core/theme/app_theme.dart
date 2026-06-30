import 'package:flutter/material.dart';

const Color voldogOrange = Color(0xFFFF6F22);
const double radiusCard = 24.0;

ThemeData buildLightTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: voldogOrange, brightness: Brightness.light);
  final warm = scheme.copyWith(
    surface: const Color(0xFFF9F6F0),
    surfaceContainerLowest: const Color(0xFFFFFCF8),
    surfaceContainerLow: const Color(0xFFFFF7EF),
    surfaceContainer: const Color(0xFFFFEFDF),
    surfaceContainerHigh: const Color(0xFFFFE8D2),
  );
  return _build(warm);
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: voldogOrange, brightness: Brightness.dark);
  final warm = scheme.copyWith(
    surface: const Color(0xFF1E1611),
    surfaceContainerLowest: const Color(0xFF241B15),
    surfaceContainerLow: const Color(0xFF2A2019),
    surfaceContainer: const Color(0xFF34281F),
    surfaceContainerHigh: const Color(0xFF3E3025),
  );
  return _build(warm);
}

ThemeData _build(ColorScheme s) {
  return ThemeData(
    colorScheme: s,
    useMaterial3: true,
    scaffoldBackgroundColor: s.surface,

    appBarTheme: AppBarTheme(centerTitle: false, backgroundColor: s.surface, foregroundColor: s.onSurface, elevation: 0, scrolledUnderElevation: 0, surfaceTintColor: Colors.transparent),

    cardTheme: CardThemeData(
      color: s.surfaceContainerLow, elevation: 0, surfaceTintColor: Colors.transparent, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: s.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: s.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
    )),

    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    )),

    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), backgroundColor: s.surfaceContainerLow, labelStyle: TextStyle(fontSize: 13, color: s.onSurface), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
    navigationBarTheme: NavigationBarThemeData(elevation: 0, surfaceTintColor: Colors.transparent, indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), labelBehavior: NavigationDestinationLabelBehavior.alwaysShow),
    navigationRailTheme: NavigationRailThemeData(indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    dividerTheme: DividerThemeData(color: s.outlineVariant.withAlpha(60), thickness: 0.5, space: 1),
  );
}
