import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the visual variants of AppRadio
enum AppRadioVariant { primary, secondary, compact, custom }

/// A customizable radio button component with multiple variants and states.
///
/// AppRadio provides a consistent radio button interface with support for
/// different visual styles (variants), labels, descriptions, and disabled states.
/// Radio buttons are typically used in groups where only one option can be selected.
///
/// Example usage:
/// ```dart
/// AppRadio<String>.primary(
///   label: 'Option 1',
///   value: 'option1',
///   groupValue: selectedValue,
///   onChanged: (value) => setState(() => selectedValue = value),
/// )
/// ```
class AppRadio<T> extends StatelessWidget {
  /// Optional label displayed next to the radio button
  final String? label;

  /// Optional description text displayed below the label
  final String? description;

  /// The value represented by this radio button
  final T value;

  /// The currently selected value in the radio button group
  final T? groupValue;

  /// Callback invoked when the radio button is selected
  final void Function(T?)? onChanged;

  /// The visual variant of the radio button
  final AppRadioVariant variant;

  /// Custom active color (overrides variant color)
  final Color? activeColor;

  /// Custom inactive color (overrides variant color)
  final Color? inactiveColor;

  const AppRadio({
    super.key,
    this.label,
    this.description,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.variant = AppRadioVariant.primary,
    this.activeColor,
    this.inactiveColor,
  });

  /// Creates a primary radio button with primary color
  factory AppRadio.primary({
    Key? key,
    String? label,
    String? description,
    required T value,
    required T? groupValue,
    void Function(T?)? onChanged,
  }) {
    return AppRadio<T>(
      key: key,
      label: label,
      description: description,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      variant: AppRadioVariant.primary,
    );
  }

  /// Creates a secondary radio button with secondary color
  factory AppRadio.secondary({
    Key? key,
    String? label,
    String? description,
    required T value,
    required T? groupValue,
    void Function(T?)? onChanged,
  }) {
    return AppRadio<T>(
      key: key,
      label: label,
      description: description,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      variant: AppRadioVariant.secondary,
    );
  }

  /// Creates a compact radio button with minimal spacing
  factory AppRadio.compact({
    Key? key,
    String? label,
    String? description,
    required T value,
    required T? groupValue,
    void Function(T?)? onChanged,
  }) {
    return AppRadio<T>(
      key: key,
      label: label,
      description: description,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      variant: AppRadioVariant.compact,
    );
  }

  /// Creates a custom radio button with specified colors
  factory AppRadio.custom({
    Key? key,
    String? label,
    String? description,
    required T value,
    required T? groupValue,
    void Function(T?)? onChanged,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return AppRadio<T>(
      key: key,
      label: label,
      description: description,
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      variant: AppRadioVariant.custom,
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
      case AppRadioVariant.primary:
        return AppColors.primary;
      case AppRadioVariant.secondary:
        return AppColors.secondary;
      case AppRadioVariant.compact:
        return AppColors.primary;
      case AppRadioVariant.custom:
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
      case AppRadioVariant.compact:
        return AppSpacing.sm;
      case AppRadioVariant.primary:
      case AppRadioVariant.secondary:
      case AppRadioVariant.custom:
        return AppSpacing.md;
    }
  }

  /// Determines if the radio button is disabled
  bool get _isDisabled => onChanged == null;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    // If there's a label, make the entire row tappable
    if (label != null) {
      return Semantics(
        inMutuallyExclusiveGroup: true,
        checked: isSelected,
        enabled: !_isDisabled,
        label: label,
        hint: description,
        child: Opacity(
          opacity: _isDisabled ? 0.5 : 1.0,
          child: InkWell(
            onTap: _isDisabled ? null : () => onChanged?.call(value),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44.0),
              padding: EdgeInsets.symmetric(
                vertical: variant == AppRadioVariant.compact
                    ? AppSpacing.xs
                    : AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRadio(),
                  SizedBox(width: _spacing),
                  Flexible(
                    fit: FlexFit.loose,
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

    // If there's no label, just show the radio button
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: isSelected,
      enabled: !_isDisabled,
      label: 'Radio button',
      child: Opacity(
        opacity: _isDisabled ? 0.5 : 1.0,
        child: Container(
          constraints: const BoxConstraints(minWidth: 44.0, minHeight: 44.0),
          child: _buildRadio(),
        ),
      ),
    );
  }

  /// Builds the radio button widget
  Widget _buildRadio() {
    return SizedBox(
      width: 24,
      height: 24,
      child: Radio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: _activeColor,
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return _activeColor;
          }
          return _inactiveColor;
        }),
      ),
    );
  }
}
