import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFF090B10);
  const surface = Color(0xFF10141C);
  const gold = Color(0xFFD6B367);
  const muted = Color(0xFFA9B3C8);

  final baseText = ThemeData.dark().textTheme.apply(fontFamily: 'Roboto');
  final luxuryText = baseText.copyWith(
    displayLarge: baseText.displayLarge
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    displayMedium: baseText.displayMedium
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    displaySmall: baseText.displaySmall
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    headlineLarge: baseText.headlineLarge
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    headlineMedium: baseText.headlineMedium
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    headlineSmall: baseText.headlineSmall
        ?.copyWith(fontFamily: 'Georgia', fontWeight: FontWeight.w600),
    titleLarge: baseText.titleLarge
        ?.copyWith(fontFamily: 'Roboto', fontWeight: FontWeight.w700),
    titleMedium: baseText.titleMedium
        ?.copyWith(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
    bodyLarge: baseText.bodyLarge?.copyWith(fontFamily: 'Roboto'),
    bodyMedium: baseText.bodyMedium?.copyWith(fontFamily: 'Roboto'),
    bodySmall: baseText.bodySmall?.copyWith(fontFamily: 'Roboto'),
    labelLarge: baseText.labelLarge?.copyWith(fontFamily: 'Roboto'),
    labelMedium: baseText.labelMedium?.copyWith(fontFamily: 'Roboto'),
    labelSmall: baseText.labelSmall?.copyWith(fontFamily: 'Roboto'),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      surface: surface,
      primary: gold,
    ).copyWith(
      background: background,
      secondary: const Color(0xFF78D2DE),
      error: const Color(0xFFD43F4F),
    ),
    textTheme: luxuryText.apply(
      bodyColor: const Color(0xFFEEF2FF),
      displayColor: const Color(0xFFEEF2FF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFFEEF2FF),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: surface.withValues(alpha: 0.88),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B1017),
      hintStyle: const TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x22111111)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x22FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0B1017),
      indicatorColor: gold.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
