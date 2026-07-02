import 'package:flutter/material.dart';
// Font: using system fonts

// ═══════════════════════════════════════════
// PawMart Design System — Flutter Theme
// ═══════════════════════════════════════════

// ——— Colors ———
class PawmartColors {
  // Primary (Olive Green)
  static const primary50 = Color(0xFFF5F7F1);
  static const primary100 = Color(0xFFE6EBDB);
  static const primary200 = Color(0xFFCFDAAA);
  static const primary300 = Color(0xFFB0C470);
  static const primary400 = Color(0xFF93AE4E);
  static const primary500 = Color(0xFF7A8B3C);
  static const primary600 = Color(0xFF647430);
  static const primary700 = Color(0xFF4C5A26);
  static const primary800 = Color(0xFF3A441E);
  static const primary900 = Color(0xFF2A3018);

  // Accent (Bright Yellow)
  static const accent50 = Color(0xFFFDFEF0);
  static const accent100 = Color(0xFFFAFCD0);
  static const accent200 = Color(0xFFF4F89D);
  static const accent300 = Color(0xFFECF166);
  static const accent400 = Color(0xFFE5E53A);
  static const accent500 = Color(0xFFD4D428);
  static const accent600 = Color(0xFFB5B520);
  static const accent700 = Color(0xFF919119);
  static const accent800 = Color(0xFF6F6F14);
  static const accent900 = Color(0xFF4E4E10);

  // Neutral
  static const neutral50 = Color(0xFFFAF9F6);
  static const neutral100 = Color(0xFFF2F0EA);
  static const neutral200 = Color(0xFFE4E0D4);
  static const neutral300 = Color(0xFFD1CBB8);
  static const neutral400 = Color(0xFFB0A894);
  static const neutral500 = Color(0xFF948A74);
  static const neutral600 = Color(0xFF7A7060);
  static const neutral700 = Color(0xFF605850);
  static const neutral800 = Color(0xFF4A443E);
  static const neutral900 = Color(0xFF36322E);

  // Semantic
  static const surfaceBg = Color(0xFFFAF9F6);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF36322E);
  static const textSecondary = Color(0xFF948A74);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnAccent = Color(0xFF36322E);
  static const error = Color(0xFFDC4A4A);
  static const info = Color(0xFF388EDC);
  static const success = Color(0xFF3F9E53);
}

// ——— Radius ———
const double pawmartRadiusSm = 6.0;
const double pawmartRadiusMd = 10.0;
const double pawmartRadiusLg = 16.0;
const double pawmartRadiusXl = 24.0;
const double pawmartRadiusFull = 9999.0;

// ——— Shadows ———
List<BoxShadow> pawmartShadow1 = [
  BoxShadow(
    color: const Color(0xFF36322E).withAlpha(15),
    blurRadius: 3,
    offset: const Offset(0, 1),
  ),
];
List<BoxShadow> pawmartShadow2 = [
  BoxShadow(
    color: const Color(0xFF36322E).withAlpha(20),
    blurRadius: 8,
    offset: const Offset(0, 4),
  ),
];
List<BoxShadow> pawmartShadow3 = [
  BoxShadow(
    color: const Color(0xFF36322E).withAlpha(25),
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

// ——— Light Theme ———
ThemeData buildLightTheme() {
  // Using default system fonts
  final textTheme = TextTheme();
  final s = ColorScheme.light(
    primary: PawmartColors.primary500,
    onPrimary: PawmartColors.textOnPrimary,
    primaryContainer: PawmartColors.primary50,
    onPrimaryContainer: PawmartColors.primary900,
    secondary: PawmartColors.accent400,
    onSecondary: PawmartColors.textOnAccent,
    secondaryContainer: PawmartColors.accent50,
    onSecondaryContainer: PawmartColors.accent900,
    tertiary: PawmartColors.neutral200,
    surface: PawmartColors.surfaceBg,
    onSurface: PawmartColors.textPrimary,
    onSurfaceVariant: PawmartColors.textSecondary,
    error: PawmartColors.error,
    outline: PawmartColors.neutral200,
    outlineVariant: PawmartColors.neutral100,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: s,
    scaffoldBackgroundColor: PawmartColors.surfaceBg,
    textTheme: textTheme,
    // primaryTextTheme: using default from colorScheme

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: PawmartColors.surfaceCard,
      foregroundColor: PawmartColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: PawmartColors.textPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: PawmartColors.surfaceCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PawmartColors.neutral50,
      hintStyle: TextStyle(
        fontSize: 14,
        color: PawmartColors.textSecondary,
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        color: PawmartColors.textSecondary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: PawmartColors.neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: PawmartColors.neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: PawmartColors.primary500, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: PawmartColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      prefixIconColor: PawmartColors.neutral400,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pawmartRadiusFull),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
        ),
        side: BorderSide(color: PawmartColors.neutral200),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
      ),
      backgroundColor: PawmartColors.neutral100,
      labelStyle: TextStyle(
        fontSize: 13,
        color: PawmartColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: PawmartColors.surfaceCard,
      indicatorColor: PawmartColors.primary100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PawmartColors.primary500,
          );
        }
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: PawmartColors.textSecondary,
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: PawmartColors.neutral200.withAlpha(120),
      thickness: 0.5,
      space: 1,
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: PawmartColors.accent400,
      foregroundColor: PawmartColors.textOnAccent,
      shape: const CircleBorder(),
    ),
  );
}

// ——— Dark Theme ———
ThemeData buildDarkTheme() {
  // Using default system fonts
  final textTheme = TextTheme();
  final s = ColorScheme.dark(
    primary: PawmartColors.primary400,
    onPrimary: PawmartColors.textOnPrimary,
    primaryContainer: PawmartColors.primary900,
    onPrimaryContainer: PawmartColors.primary100,
    secondary: PawmartColors.accent300,
    onSecondary: const Color(0xFF2A2622),
    secondaryContainer: PawmartColors.accent900,
    onSecondaryContainer: PawmartColors.accent100,
    tertiary: PawmartColors.neutral700,
    surface: const Color(0xFF1E1B18),
    onSurface: const Color(0xFFF2F0EA),
    onSurfaceVariant: const Color(0xFFB0A894),
    error: const Color(0xFFEF6E6E),
    outline: const Color(0xFF4A443E),
    outlineVariant: const Color(0xFF3C3730),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: s,
    scaffoldBackgroundColor: const Color(0xFF1E1B18),
    textTheme: textTheme,
    primaryTextTheme: textTheme,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: const Color(0xFF2A2622),
      foregroundColor: const Color(0xFFF2F0EA),
      elevation: 0,
      scrolledUnderElevation: 2,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF2F0EA),
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF2A2622),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF322E28),
      hintStyle: TextStyle(
        fontSize: 14,
        color: const Color(0xFFB0A894),
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        color: const Color(0xFFB0A894),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: const Color(0xFF4A443E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: const Color(0xFF4A443E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
        borderSide: BorderSide(color: PawmartColors.primary400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      prefixIconColor: const Color(0xFFB0A894),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pawmartRadiusFull),
        ),
        textStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pawmartRadiusMd),
        ),
        side: BorderSide(color: const Color(0xFF4A443E)),
        textStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusFull),
      ),
      backgroundColor: const Color(0xFF3C3730),
      labelStyle: TextStyle(
        fontSize: 13,
        color: const Color(0xFFF2F0EA),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xFF2A2622),
      indicatorColor: PawmartColors.primary800,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusLg),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pawmartRadiusMd),
      ),
    ),
  );
}

/// Shared decorator for pill-shaped cards
BoxDecoration pawmartCardDecoration({
  Color backgroundColor = PawmartColors.surfaceCard,
  bool elevated = false,
}) {
  return BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(pawmartRadiusMd),
    boxShadow: elevated ? pawmartShadow1 : null,
  );
}

/// Section title row used on home & product pages
Widget pawmartSectionHeader(String title, {String? actionLabel, VoidCallback? onAction}) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          color: PawmartColors.primary500,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: PawmartColors.textPrimary,
        ),
      ),
      const Spacer(),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            '$actionLabel >',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: PawmartColors.primary500,
            ),
          ),
        ),
    ],
  );
}
