import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Black & Deep Space Palette
  static const Color pureBlack = Color(0xFF000000);
  static const Color darkNavy = Color(0xFF000000); // Pure Black as requested
  static const Color surfaceNavy = Color(0xFF070B14);
  static const Color cardNavy = Color(0xFF0D172A);
  static const Color cardNavyHover = Color(0xFF162544);
  static const Color borderNavy = Color(0xFF1E2E4A);

  // Premium Black & Electric Cyan Theme Palette (Exact User Specifications)
  static const Color primaryBlack = Color(0xFF000000);
  static const Color secondaryBlack = Color(0xFF080808);
  static const Color cardBlack = Color(0xFF111111);
  static const Color glassSurface = Color(0xFF161616);
  static const Color darkBorder = Color(0xFF303030);
  static const Color textPrimaryWhite = Color(0xFFFFFFFF);
  static const Color textSecondaryGrey = Color(0xFFB3B3B3);
  static const Color cyanAccent = Color(0xFF00D9FF);
  static const Color electricCyan = Color(0xFF00BFFF);

  // Accents
  static const Color accentCyan = Color(0xFF00D2FF);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentGold = Color(0xFFFBBF24);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);

  // Text Colors
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDarkNavy = Color(0xFF0F172A);

  static ThemeData get luxuryDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkNavy,
      primaryColor: accentCyan,
      colorScheme: const ColorScheme.dark(
        primary: accentCyan,
        secondary: accentBlue,
        tertiary: accentGold,
        surface: surfaceNavy,
        error: accentRose,
        onPrimary: darkNavy,
        onSurface: textLight,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textLight),
      ),
      cardTheme: CardThemeData(
        color: cardNavy,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderNavy, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardNavy,
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNavy),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderNavy),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentCyan,
          side: const BorderSide(color: accentCyan, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
