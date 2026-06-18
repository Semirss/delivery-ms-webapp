import 'package:flutter/material.dart';
import '../common/app_icon.dart';
import '../../config/constants/app_colors.dart';

/// Enum defining the visual variants of AppIconButton
enum AppIconButtonVariant { primary, secondary, tertiary, ghost, custom }

/// Enum defining the size variants of AppIconButton
enum AppIconButtonSize { small, medium, large }

/// A circular icon-only button component with multiple variants and states.
///
/// AppIconButton provides a consistent icon button interface with support for
/// different visual styles (variants), sizes, loading states, and custom colors.
/// All icon buttons have a circular shape for a modern, clean appearance.
///
/// Example usage:
/// ```dart
/// AppIconButton.primary(
///   icon: Icons.add,
///   onPressed: () => print('Pressed'),
/// )
/// ```
class AppIconButton extends StatelessWidget {
  /// The icon to display in the button (IconData, SVG path, Image path, or Widget)
  final dynamic icon;

  /// Callback invoked when the button is pressed
  final VoidCallback? onPressed;

  /// The visual variant of the button
  final AppIconButtonVariant variant;

  /// The size variant of the button
  final AppIconButtonSize size;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Custom background color (overrides variant color)
  final Color? customBackgroundColor;

  /// Custom foreground color for icon (overrides variant color)
  final Color? customForegroundColor;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = AppIconButtonVariant.primary,
    this.size = AppIconButtonSize.medium,
    this.isLoading = false,
    this.customBackgroundColor,
    this.customForegroundColor,
  });

  /// Creates a primary icon button with filled background
  factory AppIconButton.primary({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppIconButtonSize size = AppIconButtonSize.medium,
    bool isLoading = false,
    Color? iconColor,
  }) {
    return AppIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      variant: AppIconButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      customForegroundColor: iconColor,
    );
  }

  /// Creates a secondary icon button with outlined style
  factory AppIconButton.secondary({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppIconButtonSize size = AppIconButtonSize.medium,
    bool isLoading = false,
    Color? iconColor,
  }) {
    return AppIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      variant: AppIconButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      customForegroundColor: iconColor,
    );
  }

  /// Creates a tertiary icon button with subtle styling
  factory AppIconButton.tertiary({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppIconButtonSize size = AppIconButtonSize.medium,
    bool isLoading = false,
    Color? iconColor,
  }) {
    return AppIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      variant: AppIconButtonVariant.tertiary,
      size: size,
      isLoading: isLoading,
      customForegroundColor: iconColor,
    );
  }

  /// Creates a ghost icon button with transparent background
  factory AppIconButton.ghost({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppIconButtonSize size = AppIconButtonSize.medium,
    bool isLoading = false,
    Color? iconColor,
  }) {
    return AppIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      variant: AppIconButtonVariant.ghost,
      size: size,
      isLoading: isLoading,
      customForegroundColor: iconColor,
    );
  }

  /// Creates a custom icon button with specified colors
  factory AppIconButton.custom({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppIconButtonSize size = AppIconButtonSize.medium,
    bool isLoading = false,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AppIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      variant: AppIconButtonVariant.custom,
      size: size,
      isLoading: isLoading,
      customBackgroundColor: backgroundColor,
      customForegroundColor: foregroundColor,
    );
  }

  /// Returns the button size (diameter) based on size variant
  double get _buttonSize {
    switch (size) {
      case AppIconButtonSize.small:
        return 32.0;
      case AppIconButtonSize.medium:
        return 40.0;
      case AppIconButtonSize.large:
        return 48.0;
    }
  }

  /// Returns the icon size based on button size
  double get _iconSize {
    switch (size) {
      case AppIconButtonSize.small:
        return 16.0;
      case AppIconButtonSize.medium:
        return 20.0;
      case AppIconButtonSize.large:
        return 24.0;
    }
  }

  /// Returns the background color based on variant and state
  Color _backgroundColor(BuildContext context) {
    if (customBackgroundColor != null) {
      return customBackgroundColor!;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case AppIconButtonVariant.primary:
        return AppColors.primary;
      case AppIconButtonVariant.secondary:
        return Colors.transparent;
      case AppIconButtonVariant.tertiary:
        return isDark ? AppColors.darkSurface : AppColors.surface;
      case AppIconButtonVariant.ghost:
        return Colors.transparent;
      case AppIconButtonVariant.custom:
        return customBackgroundColor ?? AppColors.primary;
    }
  }

  /// Returns the foreground color based on variant and state
  Color _foregroundColor(BuildContext context) {
    if (customForegroundColor != null) {
      return customForegroundColor!;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (variant) {
      case AppIconButtonVariant.primary:
        return Colors.white;
      case AppIconButtonVariant.secondary:
        return isDark
            ? const Color(0xFF60A5FA)
            : AppColors.primary; // Brighter blue for dark mode
      case AppIconButtonVariant.tertiary:
        return isDark
            ? const Color(0xFFE5E7EB)
            : AppColors.textPrimary; // Lighter gray for dark mode
      case AppIconButtonVariant.ghost:
        return isDark
            ? const Color(0xFFE5E7EB)
            : AppColors.textPrimary; // Lighter gray for dark mode
      case AppIconButtonVariant.custom:
        return customForegroundColor ?? Colors.white;
    }
  }

  /// Returns the border side based on variant
  BorderSide? _borderSide(BuildContext context) {
    switch (variant) {
      case AppIconButtonVariant.secondary:
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BorderSide(
          color:
              customForegroundColor ??
              (isDark
                  ? const Color(0xFF60A5FA)
                  : AppColors.primary), // Brighter blue for dark mode
          width: 1.5,
        );
      case AppIconButtonVariant.primary:
      case AppIconButtonVariant.tertiary:
      case AppIconButtonVariant.ghost:
      case AppIconButtonVariant.custom:
        return null;
    }
  }

  /// Determines if the button is disabled
  bool get _isDisabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = _foregroundColor(context);
    final borderSide = _borderSide(context);
    final backgroundColor = _backgroundColor(context);

    return Semantics(
      button: true,
      enabled: !_isDisabled && !isLoading,
      label: 'Icon button',
      hint: isLoading ? 'Loading' : null,
      child: Opacity(
        opacity: _isDisabled ? 0.5 : 1.0,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: _buttonSize >= 44.0 ? _buttonSize : 44.0,
              height: _buttonSize >= 44.0 ? _buttonSize : 44.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: borderSide != null
                    ? Border.all(
                        color: borderSide.color,
                        width: borderSide.width,
                      )
                    : null,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            foregroundColor,
                          ),
                        ),
                      )
                    : AppIcon(
                        icon: icon,
                        size: _iconSize,
                        color: foregroundColor,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
