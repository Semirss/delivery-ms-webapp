import 'package:flutter/material.dart';
import '../common/app_icon.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the visual variants of AppButton
/// Enum defining the visual variants of AppButton
enum AppButtonVariant {
  primary,
  secondary,
  outlinedPrimary,
  outlinedSecondary,
  danger,
  outlinedDanger,
  inactive,
  secondOption,
  tertiary,
  ghost,
  custom,
}

/// Enum defining the size variants of AppButton
enum AppButtonSize { small, medium, large }

/// A customizable button component with multiple variants and states.
///
/// AppButton provides a consistent button interface with support for
/// different visual styles (variants), sizes, loading states, and custom colors.
///
/// Example usage:
/// ```dart
/// AppButton.primary(
///   label: 'Submit',
///   onPressed: () => print('Pressed'),
/// )
/// ```
class AppButton extends StatelessWidget {
  /// The text label displayed on the button
  final String label;

  /// Callback invoked when the button is pressed
  final VoidCallback? onPressed;

  /// The visual variant of the button
  final AppButtonVariant variant;

  /// The size variant of the button
  final AppButtonSize size;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Optional icon to display alongside the label (IconData, SVG path, Image path, or Widget)
  final dynamic icon;

  /// Whether the button should take up the full width of its container
  final bool fullWidth;

  /// Custom background color (overrides variant color)
  final Color? customBackgroundColor;

  /// Custom foreground color for text and icon (overrides variant color)
  final Color? customForegroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
    this.customBackgroundColor,
    this.customForegroundColor,
  });

  /// Creates a primary color button with filled background (#131C43)
  factory AppButton.primary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a secondary color button with filled background (#E87E27)
  factory AppButton.secondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a danger color button with filled background (Error color)
  factory AppButton.danger({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.danger,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates an outlined danger button
  factory AppButton.outlinedDanger({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outlinedDanger,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates an outlined primary button
  factory AppButton.outlinedPrimary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outlinedPrimary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates an outlined secondary button
  factory AppButton.outlinedSecondary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.outlinedSecondary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates an inactive button style
  factory AppButton.inactive({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.inactive,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a second option button style (Gray 2)
  factory AppButton.secondOption({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.secondOption,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a tertiary button with subtle styling
  factory AppButton.tertiary({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.tertiary,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates a ghost button with transparent background
  factory AppButton.ghost({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.ghost,
      size: size,
      isLoading: isLoading,
      icon: icon,
      fullWidth: fullWidth,
    );
  }

  /// Creates an icon-only button
  factory AppButton.icon({
    Key? key,
    required dynamic icon,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    AppButtonVariant variant = AppButtonVariant.primary,
  }) {
    return AppButton(
      key: key,
      label: '',
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
      icon: icon,
    );
  }

  /// Creates a custom button with specified colors
  factory AppButton.custom({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    dynamic icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool fullWidth = false,
  }) {
    return AppButton(
      key: key,
      label: label,
      onPressed: onPressed,
      variant: AppButtonVariant.custom,
      size: size,
      isLoading: isLoading,
      icon: icon,
      customBackgroundColor: backgroundColor,
      customForegroundColor: foregroundColor,
      fullWidth: fullWidth,
    );
  }

  /// Returns the padding based on button size
  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  /// Returns the text style based on button size
  TextStyle get _textStyle {
    return AppTypography.button;
  }

  /// Returns the icon size based on button size
  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16.0;
      case AppButtonSize.medium:
        return 20.0;
      case AppButtonSize.large:
        return 24.0;
    }
  }

  /// Returns the background color based on variant and state
  Color _backgroundColor(BuildContext context) {
    if (customBackgroundColor != null) {
      return customBackgroundColor!;
    }

    final colorScheme = Theme.of(context).colorScheme;

    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary;
      case AppButtonVariant.secondary:
        return AppColors.secondary;
      case AppButtonVariant.danger:
        return AppColors.error;
      case AppButtonVariant.outlinedPrimary:
      case AppButtonVariant.outlinedSecondary:
      case AppButtonVariant.outlinedDanger:
        return Colors.transparent;
      case AppButtonVariant.inactive:
        return colorScheme.surfaceContainerHighest;
      case AppButtonVariant.secondOption:
        return AppColors.gray2;
      case AppButtonVariant.tertiary:
        return colorScheme.surfaceContainerHighest;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.custom:
        return customBackgroundColor ?? AppColors.primary;
    }
  }

  /// Returns the foreground color based on variant and state
  Color _foregroundColor(BuildContext context) {
    if (customForegroundColor != null) {
      return customForegroundColor!;
    }

    final colorScheme = Theme.of(context).colorScheme;

    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
      case AppButtonVariant.secondOption:
        return Colors.white;
      case AppButtonVariant.outlinedPrimary:
        return AppColors.primary;
      case AppButtonVariant.outlinedSecondary:
        return AppColors.secondary;
      case AppButtonVariant.outlinedDanger:
        return AppColors.error;
      case AppButtonVariant.inactive:
        return colorScheme.onSurface.withValues(alpha: 0.5);
      case AppButtonVariant.tertiary:
      case AppButtonVariant.ghost:
        return colorScheme.onSurface;
      case AppButtonVariant.custom:
        return customForegroundColor ?? Colors.white;
    }
  }

  /// Returns the border side based on variant
  BorderSide? _borderSide(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.outlinedPrimary:
        return const BorderSide(color: AppColors.primary, width: 2.0);
      case AppButtonVariant.outlinedSecondary:
        return const BorderSide(color: AppColors.secondary, width: 2.0);
      case AppButtonVariant.outlinedDanger:
        return const BorderSide(color: AppColors.error, width: 2.0);
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
      case AppButtonVariant.inactive:
      case AppButtonVariant.secondOption:
      case AppButtonVariant.tertiary:
      case AppButtonVariant.ghost:
      case AppButtonVariant.custom:
        return null;
    }
  }

  /// Determines if the button is disabled
  bool get _isDisabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isIconOnly = label.isEmpty && icon != null;
    final foregroundColor = _foregroundColor(context);
    final borderSide = _borderSide(context);
    final backgroundColor = _backgroundColor(context);

    return Semantics(
      button: true,
      enabled: !_isDisabled && !isLoading,
      label: label.isNotEmpty ? label : null,
      hint: isLoading ? 'Loading' : null,
      child: Opacity(
        opacity: _isDisabled ? 0.5 : 1.0,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: fullWidth ? double.infinity : null,
              constraints: const BoxConstraints(
                minWidth: 44.0,
                minHeight: 44.0,
              ),
              padding: _padding,
              decoration: BoxDecoration(
                border: borderSide != null
                    ? Border.all(
                        color: borderSide.color,
                        width: borderSide.width,
                      )
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          foregroundColor,
                        ),
                      ),
                    )
                  else if (icon != null) ...[
                    AppIcon(
                      icon: icon,
                      size: _iconSize,
                      color: foregroundColor,
                    ),
                    if (label.isNotEmpty) const SizedBox(width: AppSpacing.sm),
                  ],
                  if (label.isNotEmpty && !isLoading)
                    AppText(
                      label,
                      variant: AppTextVariant.button,
                      color: foregroundColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
