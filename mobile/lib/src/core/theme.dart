import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WoodGuardColors {
  static const ink = Color(0xFF18253F);
  static const forest = Color(0xFF234FCA);
  static const pine = Color(0xFF4F5D78);
  static const ember = Color(0xFF2F67FF);
  static const amber = Color(0xFFF0A945);
  static const linen = Color(0xFFEFF3FB);
  static const sand = Color(0xFFF0F4FC);
  static const danger = Color(0xFFE26172);
  static const success = Color(0xFF1DB97B);
  static const appSurface = Color(0xC7EFF3FB);
  static const panel = Color(0xD6FFFFFF);
  static const panelAlt = Color(0xEBF8FAFF);
  static const line = Color(0x2E6480B3);
  static const glass = Color(0xC7FFFFFF);
  static const sidebarStart = Color(0xFF26478D);
  static const sidebarEnd = Color(0xFF162A56);
}

ThemeData buildWoodGuardTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: WoodGuardColors.ember,
    brightness: Brightness.light,
    primary: WoodGuardColors.ember,
    secondary: WoodGuardColors.amber,
    surface: WoodGuardColors.panel,
  );

  final baseTextTheme = GoogleFonts.manropeTextTheme();
  final mono = GoogleFonts.ibmPlexMonoTextTheme();
  final heading = GoogleFonts.spaceGrotesk(
    color: WoodGuardColors.ink,
    fontWeight: FontWeight.w700,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: WoodGuardColors.linen,
    canvasColor: Colors.transparent,
    dividerColor: WoodGuardColors.line,
    textTheme: baseTextTheme.copyWith(
      displayLarge: heading.copyWith(fontSize: 42, height: 0.96),
      displayMedium: heading.copyWith(fontSize: 34, height: 0.98),
      headlineLarge: heading.copyWith(fontSize: 30, height: 1),
      headlineMedium: heading.copyWith(fontSize: 26, height: 1.05),
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
      labelLarge: mono.labelLarge?.copyWith(
        color: WoodGuardColors.pine,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      labelMedium: mono.labelMedium?.copyWith(
        color: WoodGuardColors.pine,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WoodGuardColors.glass,
      labelStyle: const TextStyle(color: WoodGuardColors.pine),
      hintStyle: const TextStyle(color: Color(0xFF7B8AA8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WoodGuardColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WoodGuardColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WoodGuardColors.ember, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WoodGuardColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: WoodGuardColors.danger, width: 1.4),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: WoodGuardColors.ember,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WoodGuardColors.ink,
        side: const BorderSide(color: WoodGuardColors.line),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: WoodGuardColors.sand,
      selectedColor: WoodGuardColors.ember,
      disabledColor: const Color(0xFFE2E8F5),
      secondarySelectedColor: WoodGuardColors.ember,
      labelStyle: const TextStyle(color: WoodGuardColors.ink),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: WoodGuardColors.panel,
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
          color: isSelected ? WoodGuardColors.ember : WoodGuardColors.pine,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
  );
}
