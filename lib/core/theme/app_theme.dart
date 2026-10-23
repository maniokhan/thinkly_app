import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
export 'app_colors.dart';

class AppTheme {
  // Styles for Thinkly Mind Map Suite compatibility
  static TextStyle get headingStyle => GoogleFonts.interTight(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyStyle => GoogleFonts.interTight(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static TextStyle get monoStyle => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static ThemeData get darkTheme {
    final baseText = GoogleFonts.ibmPlexSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: baseText.copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.ibmPlexSans(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.ibmPlexSans(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Alias lightTheme to darkTheme to maintain strict matte black aesthetics
  static ThemeData get lightTheme => darkTheme;
}
