import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WoodGuardColors {
  static const ink = Color(0xFF18253F);
  static const forest = Color(0xFF234FCA);
  static const pine = Color(0xFF4F5D78);
  static const ember = Color(0xFF2F67FF);
  static const amber = Color(0xFFF0A945);
<<<<<<< HEAD
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
=======
  static const linen = Color(0xFFF3F7FF);
  static const sand = Color(0xFFE7EEFF);
  static const mist = Color(0xFFDCE7FF);
  static const night = Color(0xFF36569B);
  static const glass = Color(0xCCFFFFFF);
  static const line = Color(0x2E6480B3);
  static const danger = Color(0xFFE26172);
  static const success = Color(0xFF1DB97B);
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
}

ThemeData buildWoodGuardTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scaffoldColor = isDark
      ? const Color(0xFF0E1527)
      : WoodGuardColors.linen;
  final surfaceColor = isDark ? const Color(0xFF16223A) : Colors.white;
  final primary = isDark ? const Color(0xFF8AB0FF) : WoodGuardColors.ember;
  final secondary = isDark ? const Color(0xFF6F95FF) : WoodGuardColors.forest;
  final onSurface = isDark ? const Color(0xFFF4F7FF) : WoodGuardColors.ink;
  final muted = isDark ? const Color(0xFFB1BED8) : WoodGuardColors.pine;
  final line = isDark ? const Color(0xFF31425F) : WoodGuardColors.line;

  final colorScheme = ColorScheme.fromSeed(
<<<<<<< HEAD
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
=======
    seedColor: primary,
    brightness: brightness,
    primary: primary,
    secondary: secondary,
    surface: surfaceColor,
  );

  final baseTextTheme = GoogleFonts.manropeTextTheme();
  final heading = GoogleFonts.spaceGrotesk(
    color: onSurface,
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
    fontWeight: FontWeight.w700,
  );

  return ThemeData(
    useMaterial3: true,
    splashFactory: InkRipple.splashFactory,
    colorScheme: colorScheme,
<<<<<<< HEAD
    scaffoldBackgroundColor: WoodGuardColors.linen,
    canvasColor: Colors.transparent,
    dividerColor: WoodGuardColors.line,
    textTheme: baseTextTheme.copyWith(
      displayLarge: heading.copyWith(fontSize: 42, height: 0.96),
      displayMedium: heading.copyWith(fontSize: 34, height: 0.98),
      headlineLarge: heading.copyWith(fontSize: 30, height: 1),
      headlineMedium: heading.copyWith(fontSize: 26, height: 1.05),
=======
    brightness: brightness,
    scaffoldBackgroundColor: scaffoldColor,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    textTheme: baseTextTheme.copyWith(
      displayLarge: heading.copyWith(fontSize: 42),
      displayMedium: heading.copyWith(fontSize: 34),
      headlineLarge: heading.copyWith(fontSize: 30),
      headlineMedium: heading.copyWith(fontSize: 26),
      headlineSmall: heading.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: onSurface,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: onSurface,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: onSurface,
        height: 1.45,
      ),
<<<<<<< HEAD
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
=======
      labelLarge: GoogleFonts.ibmPlexMono(
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: muted, height: 1.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? surfaceColor.withValues(alpha: 0.86)
          : Colors.white.withValues(alpha: 0.8),
      labelStyle: TextStyle(color: muted),
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ).copyWith(
            animationDuration: const Duration(milliseconds: 220),
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? Colors.white.withValues(alpha: 0.12)
                  : null,
            ),
            shadowColor: WidgetStatePropertyAll(
              primary.withValues(alpha: isDark ? 0.16 : 0.24),
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: secondary,
            side: BorderSide(color: line),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            backgroundColor: isDark
                ? surfaceColor.withValues(alpha: 0.56)
                : Colors.white.withValues(alpha: 0.56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ).copyWith(
            animationDuration: const Duration(milliseconds: 220),
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? secondary.withValues(alpha: 0.08)
                  : null,
            ),
          ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark
          ? surfaceColor.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.58),
      selectedColor: onSurface,
      disabledColor: isDark ? surfaceColor : WoodGuardColors.sand,
      secondarySelectedColor: onSurface,
      labelStyle: TextStyle(color: onSurface),
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: line),
      ),
    ),
    cardTheme: CardThemeData(
<<<<<<< HEAD
      color: WoodGuardColors.panel,
=======
      color: isDark
          ? surfaceColor.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.84),
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: onSurface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark
          ? surfaceColor.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.84),
      indicatorColor: onSurface,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
<<<<<<< HEAD
          color: isSelected ? WoodGuardColors.ember : WoodGuardColors.pine,
=======
          color: isSelected ? onSurface : muted,
>>>>>>> b441d82364d200e118dd68b4bcefa0f1e21dc742
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    dividerColor: line,
  );
}
