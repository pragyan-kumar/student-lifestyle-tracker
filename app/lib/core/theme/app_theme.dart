import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design system for EcoLife.
/// Colours follow a green-teal palette to reinforce the eco-sustainability theme.
class AppTheme {
  AppTheme._();

  // ── Brand Colour Palette ─────────────────────────────────────────────────
  static const Color primaryTeal     = Color(0xFF14E6C8); // Primary Teal
  static const Color primaryGreen    = primaryTeal;       // Backwards-compatible alias
  static const Color secondaryBlue   = Color(0xFF4A7DFF); // Secondary Blue
  static const Color secondaryTeal   = secondaryBlue;     // Backwards-compatible alias
  static const Color accentAmber     = Color(0xFFFFB800); // Amber — rewards & points
  static const Color successGreen    = Color(0xFF10B981); // Modern Success Green
  static const Color errorRed        = Color(0xFFEF4444); // Modern Red
  static const Color warningOrange   = Color(0xFFFF9500); // Warm Alert / Streak (removed neon purple)

  // ── Dark Theme Surfaces (Linear & Apple Health inspired) ──────────────────
  static const Color darkBackground  = Color(0xFF0C0E14); // Deep graphite
  static const Color darkSurface     = Color(0xFF12151F); // Clean slate surface
  static const Color darkCard        = Color(0xFF171B26); // Card surface
  static const Color darkCardElevated= Color(0xFF1D2232); // Slightly raised card
  static const Color darkBorder      = Color(0xFF232838); // Subtle 1px border
  static const Color darkBorderSubtle= Color(0xFF1C202E); // Soft border
  static const Color darkText        = Color(0xFFF3F4F6); // High-contrast clean white
  static const Color darkTextMuted   = Color(0xFF8E95A5); // Muted secondary text

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
        displayLarge : GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w800, color: displayColor, letterSpacing: -0.5),
        displayMedium: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w700, color: displayColor, letterSpacing: -0.3),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: displayColor),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: displayColor),
        titleLarge   : GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: bodyColor),
        titleMedium  : GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: bodyColor),
        titleSmall   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: bodyColor),
        bodyLarge    : GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w400, color: bodyColor),
        bodyMedium   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: bodyColor),
        bodySmall    : GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor.withOpacity(0.75)),
        labelLarge   : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: bodyColor),
        labelMedium  : GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: bodyColor),
      );

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary        : primaryTeal,
      secondary      : secondaryBlue,
      tertiary       : accentAmber,
      error          : errorRed,
      surface        : darkSurface,
      onPrimary      : Colors.black,
      onSecondary    : Colors.white,
      onSurface      : darkText,
    ),
    scaffoldBackgroundColor: darkBackground,
    textTheme: _buildTextTheme(darkText, darkText),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        backgroundColor: primaryTeal,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryTeal, width: 1.5),
      ),
      labelStyle: GoogleFonts.poppins(color: darkTextMuted),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryTeal,
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
