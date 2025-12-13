import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sistema tipográfico moderno para ClassicDrive.
class AppTypography {
  AppTypography._();

  // ══════════════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ══════════════════════════════════════════════════════════════════════════
  
  static String get fontFamily => GoogleFonts.poppins().fontFamily!;
  static String get fontFamilyDisplay => GoogleFonts.plusJakartaSans().fontFamily!;

  // ══════════════════════════════════════════════════════════════════════════
  // DARK MODE TEXT STYLES
  // ══════════════════════════════════════════════════════════════════════════
  
  static TextTheme get darkTextTheme => TextTheme(
    // Display - Para títulos muito grandes
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),

    // Headline - Para títulos de secções
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),

    // Title - Para títulos de cards e itens
    titleLarge: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0.1,
    ),

    // Body - Para texto de conteúdo
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextSecondary,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextSecondary,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.darkTextTertiary,
      letterSpacing: 0.4,
      height: 1.5,
    ),

    // Label - Para botões e chips
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextSecondary,
      letterSpacing: 0.5,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT MODE TEXT STYLES
  // ══════════════════════════════════════════════════════════════════════════
  
  static TextTheme get lightTextTheme => TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 57,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 45,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    headlineLarge: GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    headlineSmall: GoogleFonts.plusJakartaSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.lightTextSecondary,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.lightTextSecondary,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.lightTextTertiary,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.lightTextSecondary,
      letterSpacing: 0.5,
    ),
  );
}
