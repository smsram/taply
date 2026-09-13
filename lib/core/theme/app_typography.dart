import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography hierarchy for Taply based on Inter font family.
class AppTypography {
  AppTypography._();

  static TextTheme createTextTheme(
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      // Page Titles (24–28px, bold)
      headlineLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.5,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryTextColor,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.2,
        height: 1.35,
      ),

      // Section Titles (17–20px, semibold)
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: -0.1,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),

      // Body (14–16px)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.4,
      ),

      // Secondary / Captions (12–14px)
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 0.2,
      ),
    );
  }

  // Light Mode Text Theme
  static final TextTheme lightTextTheme = createTextTheme(
    AppColors.primaryText,
    AppColors.secondaryText,
  );

  // Dark Mode Text Theme
  static final TextTheme darkTextTheme = createTextTheme(
    AppColors.darkPrimaryText,
    AppColors.darkSecondaryText,
  );
}
