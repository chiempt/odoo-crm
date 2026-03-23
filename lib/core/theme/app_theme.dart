import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';

class AppTheme {
  static const Color primarySeedColor = Color(0xFF6B4C7E);

  static TextTheme createTextTheme(AppFont font, double scale) {
    TextTheme baseTheme = GoogleFonts.nunitoSansTextTheme();

    switch (font) {
      case AppFont.inter:
        baseTheme = GoogleFonts.interTextTheme();
        break;
      case AppFont.roboto:
        baseTheme = GoogleFonts.robotoTextTheme();
        break;
      case AppFont.nunitoSans:
        baseTheme = GoogleFonts.nunitoSansTextTheme();
        break;
    }

    // Apply scale and custom weights if needed
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: 57 * scale,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: 45 * scale,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: 36 * scale,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: 32 * scale,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: 28 * scale,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: 24 * scale,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: 16 * scale,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: 16 * scale),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: 14 * scale),
      bodySmall: baseTheme.bodySmall?.copyWith(fontSize: 12 * scale),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(fontSize: 12 * scale),
      labelSmall: baseTheme.labelSmall?.copyWith(fontSize: 11 * scale),
    );
  }

  static ThemeData createThemeData({
    required Brightness brightness,
    required AppFont font,
    required double fontSizeScale,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: brightness,
    );

    final textTheme = createTextTheme(font, fontSizeScale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? colorScheme.primary
            : Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: brightness == Brightness.light
              ? colorScheme.onPrimary
              : colorScheme.onPrimaryContainer,
          backgroundColor: brightness == Brightness.light
              ? colorScheme.primary
              : colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
    );
  }
}
