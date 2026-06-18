import 'package:flutter/material.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_radius.dart';
import '../../config/constants/app_shadows.dart';
import '../../config/constants/app_spacing.dart';

/// Enum defining the visual variants of AppCard
enum AppCardVariant { elevated, outlined, filled }

/// A card component with consistent styling.
///
/// AppCard provides a container with elevation, border, or filled background
/// following the App UI design system.
class AppCard extends StatelessWidget {
  /// The child widget to display inside the card
  final Widget child;

  /// The visual variant of the card
  final AppCardVariant variant;

  /// Optional callback when the card is tapped
  final VoidCallback? onTap;

  /// Padding inside the card
  final EdgeInsets? padding;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom border color (for outlined variant)
  final Color? borderColor;

  /// Border radius
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
  });

  /// Creates an elevated card with shadow
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.elevated,
      onTap: onTap,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Creates an outlined card with border
  factory AppCard.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? borderColor,
    BorderRadius? borderRadius,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.outlined,
      onTap: onTap,
      padding: padding,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  /// Creates a filled card with background color
  factory AppCard.filled({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return AppCard(
      key: key,
      variant: AppCardVariant.filled,
      onTap: onTap,
      padding: padding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Color _backgroundColor(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case AppCardVariant.elevated:
        return isDark ? AppColors.darkSurface : AppColors.surface;
      case AppCardVariant.outlined:
        return Colors.transparent;
      case AppCardVariant.filled:
        return isDark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    }
  }

  List<BoxShadow>? get _boxShadow {
    if (variant == AppCardVariant.elevated) {
      return AppShadows.sm;
    }
    return null;
  }

  Border? _border(BuildContext context) {
    if (variant == AppCardVariant.outlined) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Border.all(
        color:
            borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border),
        width: 1,
      );
    }
    return null;
  }

  BorderRadius get _borderRadius {
    return borderRadius ?? BorderRadius.circular(AppRadius.lg);
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: _borderRadius,
        boxShadow: _boxShadow,
        border: _border(context),
      ),
      child: child,
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: _borderRadius,
            child: cardContent,
          ),
        ),
      );
    }

    return cardContent;
  }
}
