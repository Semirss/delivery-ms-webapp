import 'package:flutter/material.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the visual variants of AppText
enum AppTextVariant {
  heading1,
  heading2,
  heading3,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
  button,
}

/// A highly customizable Text component that strictly adheres to the App UI
/// typography system.
///
/// This component allows you to use standard typography tokens within `const`
/// widget trees. It resolves the non-const GoogleFonts internally during `build`.
class AppText extends StatelessWidget {
  /// The text string to display
  final String? text;

  /// The typography variant to apply
  final AppTextVariant variant;

  /// Optional text color override
  final Color? color;

  /// Optional text alignment
  final TextAlign? textAlign;

  /// Optional maximum number of lines
  final int? maxLines;

  /// Optional text overflow handling
  final TextOverflow? overflow;

  /// Optional weight override
  final FontWeight? fontWeight;

  /// Optional TextSpan for rich text
  final InlineSpan? textSpan;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  }) : textSpan = null;

  const AppText.rich(
    this.textSpan, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  }) : text = null;

  @override
  Widget build(BuildContext context) {
    TextStyle baseStyle;

    switch (variant) {
      case AppTextVariant.heading1:
        baseStyle = AppTypography.heading1;
        break;
      case AppTextVariant.heading2:
        baseStyle = AppTypography.heading2;
        break;
      case AppTextVariant.heading3:
        baseStyle = AppTypography.heading3;
        break;
      case AppTextVariant.bodyLarge:
        baseStyle = AppTypography.bodyLarge;
        break;
      case AppTextVariant.bodyMedium:
        baseStyle = AppTypography.bodyMedium;
        break;
      case AppTextVariant.bodySmall:
        baseStyle = AppTypography.bodySmall;
        break;
      case AppTextVariant.labelLarge:
        baseStyle = AppTypography.labelLarge;
        break;
      case AppTextVariant.labelMedium:
        baseStyle = AppTypography.labelMedium;
        break;
      case AppTextVariant.labelSmall:
        baseStyle = AppTypography.labelSmall;
        break;
      case AppTextVariant.button:
        baseStyle = AppTypography.button;
        break;
    }

    // Apply color, weight overrides if provided
    final effectiveStyle = baseStyle.copyWith(
      color: color ?? Theme.of(context).colorScheme.onSurface,
      fontWeight: fontWeight,
    );

    if (textSpan != null) {
      return Text.rich(
        textSpan!,
        style: effectiveStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Text(
      text ?? '',
      style: effectiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
