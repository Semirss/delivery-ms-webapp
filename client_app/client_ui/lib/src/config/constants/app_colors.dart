import 'package:flutter/material.dart';

/// primary, secondary, accent, neutral, semantic, and dark mode variants.
abstract class AppColors {
  // Primary Palette
  /// Primary brand color used for main actions and emphasis
  static const Color primary = Color(0xFFF26A54);

  /// Lighter variant of primary color for hover states and accents
  static const Color primaryLight = Color(0xFFFF9A84);

  /// Darker variant of primary color for pressed states
  static const Color primaryDark = Color(0xFF7A3C8D);
  // Secondary Palette
  /// Secondary brand color for complementary actions
  static const Color secondary = Color(0xFF2AA7D6);

  /// Lighter variant of secondary color
  static const Color secondaryLight = Color(0xFF67D2F0);

  /// Darker variant of secondary color
  static const Color secondaryDark = Color(0xFF1D5E98);

  // Accent Colors
  /// Accent color 1 - Cyan
  static const Color accent1 = Color(0xFF06B6D4);

  /// Accent color 2 - Green
  static const Color accent2 = Color(0xFF84C84F);

  /// Accent color 3 - Amber (Third color)
  static const Color accent3 = Color(0xFFFF8A5B);

  /// Third brand color
  static const Color third = Color(0xFFFF8A5B);

  /// Accent color 4 - Red
  static const Color accent4 = Color(0xFFB14C96);

  /// First brand color
  static const Color accent5 = Color(0xFF513077);

  /// Accent color for backgrounds
  static const Color accent = Color(0xFFF3F4F6);

  // Neutral Palette
  /// Main background color for light theme
  static const Color background = Color(0xFFFFFFFF);

  /// Surface color for cards and elevated elements
  static const Color surface = Color(0xFFF9FAFB);

  /// Alternative surface color for subtle differentiation
  static const Color surfaceAlt = Color(0xFFF3F4F6);

  /// Border color for dividers and outlines
  static const Color border = Color(0xFFE5E7EB);

  /// Border color for dividers and outlines
  static const Color divider = Color.fromARGB(255, 230, 231, 234);

  /// Light gray border color for text fields
  static const Color textFieldBorder = Color(0xFFDCDCDC);

  /// Primary text color for main content
  static const Color textPrimary = Color(0xFF12263D);

  /// Secondary text color for supporting content (MRP Text Gray)
  static const Color textSecondary = Color(0xFF9FA0B1);

  /// Disabled text color for inactive elements
  static const Color textDisabled = Color(0xFF9CA3AF);

  /// Text Gray (#9FA0B1)
  static const Color textGray = Color(0xFF9FA0B1);

  /// Gray 1 (#525365)
  static const Color gray1 = Color(0xFF525365);

  /// Gray 2 (#83849A)
  static const Color gray2 = Color(0xFF83849A);

  /// Text light Gray (#C1C2CD)
  static const Color textLightGray = Color(0xFFC1C2CD);

  /// Text light Gray2 (#E9EAEC)
  static const Color textLightGray2 = Color(0xFFE9EAEC);

  /// Neutral Blue (#2D8AA7)
  static const Color neutralBlue = Color(0xFF183A59);

  /// Light Blue bg (#F4F4F7)
  static const Color lightBlueBg = Color(0xFFF4F4F7);

  // Semantic Colors
  /// Success color for positive actions and states
  static const Color success = Color(0xFF2DBA87);

  /// Warning color for cautionary messages
  static const Color warning = Color(0xFFF59E0B);

  /// Error color for error states and destructive actions
  static const Color error = Color(0xFFEF4444);

  static const Color errorLight = Color(0xFFFCA5A5);

  static const Color errorDark = Color(0xFFB91C1C);

  static const Color danger = error;

  /// Info color for informational messages
  static const Color info = Color(0xFF3B82F6);

  // Dark Mode Variants
  /// Dark theme background color
  static const Color darkBackground = Color(0xFF111827);

  /// Dark theme surface color
  static const Color darkSurface = Color(0xFF1F2937);

  /// Dark theme alternative surface color
  static const Color darkSurfaceAlt = Color(0xFF374151);

  /// Dark theme border color
  static const Color darkBorder = Color(0xFF4B5563);

  /// Dark theme primary text color
  static const Color darkTextPrimary = Color(0xFFF9FAFB);

  /// Dark theme secondary text color
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
}
