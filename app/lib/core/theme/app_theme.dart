import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for EcoLife.
/// Colours follow a green-teal palette to reinforce the eco-sustainability theme.
class AppTheme {
  AppTheme._();

  // ── Brand Colour Palette ─────────────────────────────────────────────────
  static const Color primaryGreen    = Color(0xFF00F5D4); // Mint Green
  static const Color secondaryTeal   = Color(0xFF2E6EE1); // Electric Blue
  static const Color accentAmber     = Color(0xFFDAA520); // Goldenrod — rewards
  static const Color errorRed        = Color(0xFFDC143C); // Crimson
  static const Color successGreen    = Color(0xFF00F5D4); // Mint Green (success)
  static const Color warningOrange   = Color(0xFF9D4EDD); // Neon Purple — streak/warning

  // ── Dark Theme Surfaces ────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF08090E); // Near-black
  static const Color darkSurface     = Color(0xFF111420); // Rich dark blue-tint
  static const Color darkCard        = Color(0xFF161A28); // Card surface
  static const Color darkBorder      = Color(0xFF252A3D); // Visible border
  static const Color darkText        = Color(0xFFEEF2FF); // Near-white cool
  static const Color darkTextMuted   = Color(0xFF7B82A8); // Muted blue-grey

  // ── Light Theme Surfaces ─────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF6F8FA);
  static const Color lightSurface    = Color(0xFFFFFFFF);
  static const Color lightCard       = Color(0xFFFFFFFF);
  static const Color lightBorder     = Color(0xFFD0D7DE);
  static const Color lightText       = Color(0xFF1F2328);
  static const Color lightTextMuted  = Color(0xFF636C76);

  // ── Typography (Poppins) ─────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color bodyColor, Color displayColor) =>
      GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge : GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: displayColor),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: displayColor),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: displayColor),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: displayColor),
        titleLarge   : GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: bodyColor),
        titleMedium  : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: bodyColor),
        bodyLarge    : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: bodyColor),
        bodyMedium   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
        bodySmall    : GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: bodyColor.withOpacity(0.7)),
        labelLarge   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: bodyColor),
      );

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary        : primaryGreen,
      secondary      : secondaryTeal,
      tertiary       : accentAmber,
      error          : errorRed,
      surface        : darkSurface,
      onPrimary      : Colors.black,
      onSecondary    : Colors.black,
      onSurface      : darkText,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: _buildTextTheme(darkText, darkText),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: darkText),
      iconTheme: const IconThemeData(color: darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(color: darkTextMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: darkTextMuted,
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
  );

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary        : primaryGreen,
      secondary      : secondaryTeal,
      tertiary       : accentAmber,
      error          : errorRed,
      surface        : lightSurface,
      onPrimary      : Colors.white,
      onSecondary    : Colors.white,
      onSurface      : lightText,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: _buildTextTheme(lightText, lightText),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: lightText),
      iconTheme: const IconThemeData(color: lightText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(color: lightTextMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryGreen,
      unselectedItemColor: lightTextMuted,
    ),
    dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
  );
}
