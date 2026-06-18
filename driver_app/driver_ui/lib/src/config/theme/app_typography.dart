import 'package:flutter/material.dart';
import '../../../app_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system providing predefined text styles for the entire application.
///
/// Defines a complete typography scale including headings, body text, and labels
/// with consistent font families and sizing. All text styles use the Inter font
/// family from Google Fonts and maintain proper line heights for readability.
///
/// Example usage:
/// ```dart
/// Text(
///   'Welcome',
///   style: AppTypography.heading1,
/// )
/// ```
abstract class AppTypography {
  // Headings
  /// Title 1 - Largest heading style
  static TextStyle title1 = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Title 2 - Secondary heading style
  static TextStyle title2 = GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Title 3 - Tertiary heading style
  static TextStyle title3 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Subtitle - Primary subtitle style
  static TextStyle subtitle = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subtitle 2 - Secondary subtitle style
  static TextStyle subtitle2 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  /// Regular 16 - Standard large body text
  static TextStyle regular16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Regular 14 - Standard medium body text
  static TextStyle regular14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Paragraph - Standard paragraph text
  static TextStyle paragraph = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Paragraph Highlight - Emphasized paragraph text
  static TextStyle paragraphHighlight = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Paragraph Link - Link text in paragraphs
  static TextStyle paragraphLink = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralBlue,
    decoration: TextDecoration.underline,
  );

  //small text
  static TextStyle smallText = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Specialized Text
  /// Button - Text style for buttons
  static TextStyle button = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.25,
  );

  /// Medium 14 Notifications - Medium weight text for notifications
  static TextStyle medium14Notifications = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Medium 14 - Standard medium weight text
  static TextStyle medium14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Captions
  /// Caption Title - Bold caption for headers
  static TextStyle captionTitle = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Caption - Standard caption text
  static TextStyle caption = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textGray,
  );

  /// Caption Regular - Regular weight caption text
  static TextStyle captionRegular = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
  );

  // Legacy/Compatibility mappings
  static TextStyle get heading1 => title1;
  static TextStyle get heading2 => title2;
  static TextStyle get heading3 => title3;
  static TextStyle get bodyLarge => regular16;
  static TextStyle get bodyMedium => regular14;
  static TextStyle get bodySmall => caption;
  static TextStyle get labelLarge => subtitle;
  static TextStyle get labelMedium => subtitle2;
  static TextStyle get labelSmall => captionRegular;
}
