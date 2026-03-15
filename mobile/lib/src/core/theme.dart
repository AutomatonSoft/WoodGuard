import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WoodGuardColors {
  static const ink = Color(0xFF1E2A25);
  static const forest = Color(0xFF2E4A3C);
  static const pine = Color(0xFF436153);
  static const ember = Color(0xFFC86D3A);
  static const amber = Color(0xFFE1A74A);
  static const linen = Color(0xFFF5EFE5);
  static const sand = Color(0xFFE9DFC9);
  static const danger = Color(0xFFB4493D);
  static const success = Color(0xFF2D7A57);
}

ThemeData buildWoodGuardTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: WoodGuardColors.ember,
    brightness: Brightness.light,
    primary: WoodGuardColors.forest,
    secondary: WoodGuardColors.ember,
    surface: Colors.white,
  );

  final baseTextTheme = GoogleFonts.manropeTextTheme();
  final heading = GoogleFonts.playfairDisplay(
    color: WoodGuardColors.ink,
    fontWeight: FontWeight.w700,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: WoodGuardColors.linen,
    textTheme: baseTextTheme.copyWith(
      displayLarge: heading.copyWith(fontSize: 42),
      displayMedium: heading.copyWith(fontSize: 34),
      headlineLarge: heading.copyWith(fontSize: 30),
      headlineMedium: heading.copyWith(fontSize: 26),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: WoodGuardColors.ink,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: WoodGuardColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: WoodGuardColors.ink,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: WoodGuardColors.ink,
        height: 1.45,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: WoodGuardColors.pine),
      hintStyle: const TextStyle(color: Color(0xFF8A8F8B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD7CBB8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFD7CBB8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: WoodGuardColors.ember, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WoodGuardColors.forest,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WoodGuardColors.forest,
        side: const BorderSide(color: WoodGuardColors.forest),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WoodGuardColors.sand,
      selectedColor: WoodGuardColors.forest,
      disabledColor: const Color(0xFFE9E1D6),
      secondarySelectedColor: WoodGuardColors.forest,
      labelStyle: const TextStyle(color: WoodGuardColors.ink),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: WoodGuardColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.94),
      indicatorColor: WoodGuardColors.sand,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          color: isSelected ? WoodGuardColors.forest : WoodGuardColors.pine,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
  );
}
