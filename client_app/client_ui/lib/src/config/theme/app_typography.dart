import 'package:flutter/material.dart';
import '../../../app_ui.dart';

/// Typography system providing predefined text styles for the entire application.
///
/// Defines a complete typography scale including headings, body text, and labels
/// with consistent sizing and bundled platform font fallbacks.
///
/// Example usage:
/// ```dart
/// Text(
///   'Welcome',
///   style: AppTypography.heading1,
/// )
/// ```
abstract class AppTypography {
  static const List<String> fontFallbacks = [
    'Noto Sans Ethiopic',
    'Noto Sans Ethiopic UI',
    'Abyssinica SIL',
    'Nyala',
    'Ebrima',
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontFamilyFallback: fontFallbacks,
    );
  }

  // Headings
  /// Title 1 - Largest heading style
  static TextStyle title1 = _style(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Title 2 - Secondary heading style
  static TextStyle title2 = _style(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Title 3 - Tertiary heading style
  static TextStyle title3 = _style(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Subtitle - Primary subtitle style
  static TextStyle subtitle = _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subtitle 2 - Secondary subtitle style
  static TextStyle subtitle2 = _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body Text
  /// Regular 16 - Standard large body text
  static TextStyle regular16 = _style(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Regular 14 - Standard medium body text
  static TextStyle regular14 = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Paragraph - Standard paragraph text
  static TextStyle paragraph = _style(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Paragraph Highlight - Emphasized paragraph text
  static TextStyle paragraphHighlight = _style(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Paragraph Link - Link text in paragraphs
  static TextStyle paragraphLink = _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.neutralBlue,
    decoration: TextDecoration.underline,
  );

  //small text
  static TextStyle smallText = _style(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Specialized Text
  /// Button - Text style for buttons
  static TextStyle button = _style(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  );

  /// Medium 14 Notifications - Medium weight text for notifications
  static TextStyle medium14Notifications = _style(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Medium 14 - Standard medium weight text
  static TextStyle medium14 = _style(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Captions
  /// Caption Title - Bold caption for headers
  static TextStyle captionTitle = _style(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Caption - Standard caption text
  static TextStyle caption = _style(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textGray,
  );

  /// Caption Regular - Regular weight caption text
  static TextStyle captionRegular = _style(
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
