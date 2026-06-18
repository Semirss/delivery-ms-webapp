import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';

/// Enum defining the visual variants of AppCheckbox
enum AppCheckboxVariant { primary, secondary, compact, custom }

/// A customizable checkbox component with multiple variants and states.
///
/// AppCheckbox provides a consistent checkbox interface with support for
/// different visual styles (variants), labels, descriptions, and disabled states.
///
/// Example usage:
/// ```dart
/// AppCheckbox.primary(
///   label: 'Accept terms',
///   value: true,
///   onChanged: (value) => print('Changed to $value'),
/// )
/// ```
class AppCheckbox extends StatelessWidget {
  /// Optional label displayed next to the checkbox
  final String? label;

  /// Optional description text displayed below the label
  final String? description;

  /// The current value of the checkbox
  final bool value;

  /// Callback invoked when the checkbox state changes
  final void Function(bool?)? onChanged;

  /// The visual variant of the checkbox
  final AppCheckboxVariant variant;

  /// Custom active color (overrides variant color)
  final Color? activeColor;

  /// Custom inactive color (overrides variant color)
  final Color? inactiveColor;

  const AppCheckbox({
    super.key,
    this.label,
    this.description,
    required this.value,
    this.onChanged,
    this.variant = AppCheckboxVariant.primary,
    this.activeColor,
    this.inactiveColor,
  });

  /// Creates a primary checkbox with primary color
  factory AppCheckbox.primary({
    Key? key,
    String? label,
    String? description,
    required bool value,
    void Function(bool?)? onChanged,
  }) {
    return AppCheckbox(
      key: key,
      label: label,
      description: description,
      value: value,
      onChanged: onChanged,
      variant: AppCheckboxVariant.primary,
    );
  }

  /// Creates a secondary checkbox with secondary color
  factory AppCheckbox.secondary({
    Key? key,
    String? label,
    String? description,
    required bool value,
    void Function(bool?)? onChanged,
  }) {
    return AppCheckbox(
      key: key,
      label: label,
      description: description,
      value: value,
      onChanged: onChanged,
      variant: AppCheckboxVariant.secondary,
    );
  }

  /// Creates a compact checkbox with minimal spacing
  factory AppCheckbox.compact({
    Key? key,
    String? label,
    String? description,
    required bool value,
    void Function(bool?)? onChanged,
  }) {
    return AppCheckbox(
      key: key,
      label: label,
      description: description,
      value: value,
      onChanged: onChanged,
      variant: AppCheckboxVariant.compact,
    );
  }

  /// Creates a custom checkbox with specified colors
  factory AppCheckbox.custom({
    Key? key,
    String? label,
    String? description,
    required bool value,
    void Function(bool?)? onChanged,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return AppCheckbox(
      key: key,
      label: label,
      description: description,
      value: value,
      onChanged: onChanged,
      variant: AppCheckboxVariant.custom,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }

  /// Returns the active color based on variant
  Color get _activeColor {
    if (activeColor != null) {
      return activeColor!;
    }

    switch (variant) {
      case AppCheckboxVariant.primary:
        return AppColors.primary;
      case AppCheckboxVariant.secondary:
        return AppColors.secondary;
      case AppCheckboxVariant.compact:
        return AppColors.primary;
      case AppCheckboxVariant.custom:
        return activeColor ?? AppColors.primary;
    }
  }

  /// Returns the inactive color based on variant
  Color get _inactiveColor {
    if (inactiveColor != null) {
      return inactiveColor!;
    }

    return AppColors.border;
  }

  /// Returns the spacing based on variant
  double get _spacing {
    switch (variant) {
      case AppCheckboxVariant.compact:
        return AppSpacing.sm;
      case AppCheckboxVariant.primary:
      case AppCheckboxVariant.secondary:
      case AppCheckboxVariant.custom:
        return AppSpacing.md;
    }
  }

  /// Determines if the checkbox is disabled
  bool get _isDisabled => onChanged == null;

  @override
  Widget build(BuildContext context) {
    // If there's a label, make the entire row tappable
    if (label != null) {
      return Semantics(
        checked: value,
        enabled: !_isDisabled,
        label: label,
        hint: description,
        child: Opacity(
          opacity: _isDisabled ? 0.5 : 1.0,
          child: InkWell(
            onTap: _isDisabled ? null : () => onChanged?.call(!value),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              padding: EdgeInsets.symmetric(
                vertical: variant == AppCheckboxVariant.compact
                    ? AppSpacing.xs
                    : AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCheckbox(),
                  SizedBox(width: _spacing),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          label!,
                          variant: AppTextVariant.bodyMedium,
                          color: _isDisabled
                              ? AppColors.textDisabled
                              : AppColors.textPrimary,
                        ),
                        if (description != null) ...[
                          SizedBox(height: AppSpacing.xs),
                          AppText(
                            description!,
                            variant: AppTextVariant.bodySmall,
                            color: _isDisabled
                                ? AppColors.textDisabled
                                : AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // If there's no label, just show the checkbox
    return Semantics(
      checked: value,
      enabled: !_isDisabled,
      label: 'Checkbox',
      child: Opacity(
        opacity: _isDisabled ? 0.5 : 1.0,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
          child: _buildCheckbox(),
        ),
      ),
    );
  }

  /// Builds the checkbox widget
  Widget _buildCheckbox() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: _activeColor,
        checkColor: Colors.white,
        side: BorderSide(color: _inactiveColor, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}
