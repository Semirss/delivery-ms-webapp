import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/app_icon.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the visual variants of AppTextField
enum AppTextFieldVariant { outlined, filled, underlined, custom }

/// Enum defining the style theme of AppTextField
enum AppTextFieldStyle {
  /// Light style - for use on light backgrounds (dark labels, white/light fills)
  light,

  /// Dark style - for use on dark backgrounds (white labels, transparent fills, light borders)
  dark,
}

/// A customizable text input component with multiple variants and states.
///
/// AppTextField provides a consistent text input interface with support for
/// different visual styles (variants), validation, icons, and various input types.
///
/// Example usage:
/// ```dart
/// AppTextField.outlined(
///   label: 'Email',
///   hint: 'Enter your email',
///   keyboardType: TextInputType.emailAddress,
/// )
/// ```
class AppTextField extends StatefulWidget {
  /// Optional label displayed above the text field
  final String? label;

  /// Optional hint text displayed when field is empty
  final String? hint;

  /// Optional error text displayed below the field
  final String? errorText;

  /// Optional controller for managing text input
  final TextEditingController? controller;

  /// Optional focus node for external focus control
  final FocusNode? focusNode;

  /// The visual variant of the text field
  final AppTextFieldVariant variant;

  /// Optional prefix icon displayed at the start of the field
  final dynamic prefixIcon;

  /// Optional suffix icon displayed at the end of the field
  final dynamic suffixIcon;

  /// Callback invoked when suffix icon is pressed
  final VoidCallback? onSuffixPressed;

  /// Callback invoked when prefix icon is pressed
  final VoidCallback? onPrefixPressed;

  /// Whether to obscure the text (for passwords)
  final bool obscureText;

  /// The type of keyboard to display
  final TextInputType keyboardType;

  /// Maximum number of lines for the text field
  final int maxLines;

  /// Optional max length for the text field
  final int? maxLength;

  /// Optional input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Text alignment within the field
  final TextAlign textAlign;

  /// Text input action for the keyboard
  final TextInputAction? textInputAction;

  /// Optional validator function
  final String? Function(String?)? validator;

  /// Custom fill color (overrides variant color)
  final Color? fillColor;

  /// Custom border color (overrides variant color)
  final Color? borderColor;

  /// Custom label color (overrides default label color)
  final Color? labelColor;

  /// Style theme for the text field (light or dark background)
  final AppTextFieldStyle? style;

  /// Whether the field is enabled
  final bool enabled;

  /// Callback invoked when text changes
  final void Function(String)? onChanged;

  /// Callback invoked when editing is complete
  final VoidCallback? onEditingComplete;

  /// Callback invoked when submitted
  final ValueChanged<String>? onSubmitted;

  /// Whether the field is read-only
  final bool readOnly;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.focusNode,
    this.variant = AppTextFieldVariant.outlined,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixPressed,
    this.onPrefixPressed,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.validator,
    this.fillColor,
    this.borderColor,
    this.labelColor,
    this.style,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.readOnly = false,
  });

  /// Creates an outlined text field
  factory AppTextField.outlined({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    TextEditingController? controller,
    dynamic prefixIcon,
    dynamic suffixIcon,
    VoidCallback? onSuffixPressed,
    VoidCallback? onPrefixPressed,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    AppTextFieldStyle? style,
    bool enabled = true,
    void Function(String)? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      variant: AppTextFieldVariant.outlined,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixPressed: onSuffixPressed,
      onPrefixPressed: onPrefixPressed,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textInputAction: textInputAction,
      validator: validator,
      style: style,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
    );
  }

  /// Creates a filled text field
  factory AppTextField.filled({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    TextEditingController? controller,
    dynamic prefixIcon,
    dynamic suffixIcon,
    VoidCallback? onSuffixPressed,
    VoidCallback? onPrefixPressed,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    AppTextFieldStyle? style,
    bool enabled = true,
    void Function(String)? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      variant: AppTextFieldVariant.filled,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixPressed: onSuffixPressed,
      onPrefixPressed: onPrefixPressed,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textInputAction: textInputAction,
      validator: validator,
      style: style,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
    );
  }

  /// Creates an underlined text field
  factory AppTextField.underlined({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    TextEditingController? controller,
    dynamic prefixIcon,
    dynamic suffixIcon,
    VoidCallback? onSuffixPressed,
    VoidCallback? onPrefixPressed,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    AppTextFieldStyle? style,
    bool enabled = true,
    void Function(String)? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      variant: AppTextFieldVariant.underlined,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixPressed: onSuffixPressed,
      onPrefixPressed: onPrefixPressed,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textInputAction: textInputAction,
      validator: validator,
      style: style,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
    );
  }

  /// Creates a custom text field with specified colors
  factory AppTextField.custom({
    Key? key,
    String? label,
    String? hint,
    String? errorText,
    TextEditingController? controller,
    dynamic prefixIcon,
    dynamic suffixIcon,
    VoidCallback? onSuffixPressed,
    VoidCallback? onPrefixPressed,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Color? fillColor,
    Color? borderColor,
    AppTextFieldStyle? style,
    bool enabled = true,
    void Function(String)? onChanged,
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool readOnly = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      label: label,
      hint: hint,
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      variant: AppTextFieldVariant.custom,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      onSuffixPressed: onSuffixPressed,
      onPrefixPressed: onPrefixPressed,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      textInputAction: textInputAction,
      validator: validator,
      fillColor: fillColor,
      borderColor: borderColor,
      style: style,
      enabled: enabled,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      readOnly: readOnly,
    );
  }

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  /// Returns the label color based on style
  Color _getLabelColor() {
    if (!widget.enabled) {
      return AppColors.textDisabled;
    }

    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          return AppColors.textPrimary; // Dark label for light background
        case AppTextFieldStyle.dark:
          return Colors.white; // White label for dark background
      }
    }

    return AppColors.textPrimary;
  }

  /// Returns the text color based on style
  Color _getTextColor() {
    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          return AppColors.textPrimary; // Dark text for light background
        case AppTextFieldStyle.dark:
          return Colors.white; // White text for dark background
      }
    }

    return AppColors.textPrimary;
  }

  /// Returns the hint color based on style
  Color _getHintColor() {
    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          return AppColors.textSecondary; // Gray hint for light background
        case AppTextFieldStyle.dark:
          return Colors.white.withOpacity(
            0.6,
          ); // Light hint for dark background
      }
    }

    return AppColors.textSecondary;
  }

  /// Returns the icon color based on style
  Color _getIconColor() {
    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          // Use darker grey for better visibility on white background
          return const Color(0xFF767676); // Darker grey for light background
        case AppTextFieldStyle.dark:
          return Colors.white.withOpacity(
            0.8,
          ); // White icon for dark background
      }
    }

    return AppColors.textSecondary;
  }

  /// Returns the fill color based on variant, style, and state
  Color get _fillColor {
    if (widget.fillColor != null) {
      return widget.fillColor!;
    }

    // Apply style-based colors if style is specified
    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          switch (widget.variant) {
            case AppTextFieldVariant.filled:
              return Colors.white;
            case AppTextFieldVariant.outlined:
            case AppTextFieldVariant.underlined:
            case AppTextFieldVariant.custom:
              return Colors.transparent;
          }
        case AppTextFieldStyle.dark:
          return Colors.transparent;
      }
    }

    // Default behavior based on variant
    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return Colors.transparent;
      case AppTextFieldVariant.filled:
        return AppColors.surface;
      case AppTextFieldVariant.underlined:
        return Colors.transparent;
      case AppTextFieldVariant.custom:
        return Colors.transparent;
    }
  }

  /// Returns the border color based on variant, style, and state
  Color get _borderColor {
    if (widget.errorText != null) {
      return AppColors.error;
    }

    if (widget.borderColor != null) {
      return widget.borderColor!;
    }

    // Apply style-based border colors if style is specified
    if (widget.style != null) {
      switch (widget.style!) {
        case AppTextFieldStyle.light:
          if (_isFocused) {
            return AppColors.primary;
          }
          return AppColors.textFieldBorder; // Light gray border
        case AppTextFieldStyle.dark:
          if (_isFocused) {
            return Colors.white; // White border for dark style when focused
          }
          return AppColors.textFieldBorder.withOpacity(
            0.4,
          ); // Light gray with transparency
      }
    }

    // Default behavior
    if (_isFocused) {
      return AppColors.primary;
    }

    if (!widget.enabled) {
      return AppColors.border.withOpacity(0.5);
    }

    return AppColors.border;
  }

  /// Returns the border based on variant, style, and state
  InputBorder get _border {
    // Show border for dark style, outlined, custom, or when borderColor is explicitly set
    final bool showBorder =
        widget.style == AppTextFieldStyle.dark ||
        widget.variant == AppTextFieldVariant.outlined ||
        widget.variant == AppTextFieldVariant.custom ||
        widget.borderColor != null ||
        (widget.style == AppTextFieldStyle.light &&
            widget.variant == AppTextFieldVariant.filled);

    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: _borderColor, width: 1.5),
        );
      case AppTextFieldVariant.filled:
        // Always use a border to prevent default underline
        // Use transparent border if not showing border to prevent underline
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: showBorder
              ? BorderSide(color: _borderColor, width: 1.5)
              : const BorderSide(color: Colors.transparent, width: 0),
        );
      case AppTextFieldVariant.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: _borderColor, width: 1.5),
        );
      case AppTextFieldVariant.custom:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: _borderColor, width: 1.5),
        );
    }
  }

  /// Returns the focused border based on variant and style
  InputBorder get _focusedBorder {
    // For dark style, use white border when focused
    final Color focusedBorderColor = widget.style == AppTextFieldStyle.dark
        ? Colors.white
        : (widget.borderColor ?? AppColors.primary);

    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
        );
      case AppTextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
        );
      case AppTextFieldVariant.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: focusedBorderColor, width: 2.0),
        );
      case AppTextFieldVariant.custom:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: widget.borderColor ?? focusedBorderColor,
            width: 2.0,
          ),
        );
    }
  }

  /// Returns the error border based on variant
  InputBorder get _errorBorder {
    switch (widget.variant) {
      case AppTextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        );
      case AppTextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        );
      case AppTextFieldVariant.underlined:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        );
      case AppTextFieldVariant.custom:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      enabled: widget.enabled,
      label: widget.label,
      hint: widget.hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            AppText(
              widget.label!,
              variant: AppTextVariant.labelMedium,
              color: widget.labelColor ?? _getLabelColor(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Material(
            color: Colors.transparent,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              textAlign: widget.textAlign,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onEditingComplete: widget.onEditingComplete,
              onSubmitted: widget.onSubmitted,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.enabled
                    ? _getTextColor()
                    : AppColors.textDisabled,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: _getHintColor(),
                ),
                filled: true,
                fillColor: _fillColor,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: widget.maxLines > 1 ? AppSpacing.lg : AppSpacing.md,
                ),
                border: _border,
                enabledBorder: _border,
                focusedBorder: _focusedBorder,
                errorBorder: _errorBorder,
                focusedErrorBorder: _errorBorder,
                disabledBorder: _border,
                // Explicitly remove all underline decorations
                isCollapsed: false,
                counterText: '',
                counterStyle: const TextStyle(height: 0, fontSize: 0),
                // Remove underline completely
                alignLabelWithHint: false,
                prefixIcon: widget.prefixIcon != null
                    ? Semantics(
                        button: true,
                        enabled: widget.onPrefixPressed != null,
                        label: 'Prefix icon button',
                        child: IconButton(
                          icon: AppIcon(
                            icon: widget.prefixIcon,
                            color: widget.errorText != null
                                ? AppColors.error
                                : _getIconColor(),
                          ),
                          color: widget.errorText != null
                              ? AppColors.error
                              : _getIconColor(),
                          onPressed: widget.onPrefixPressed,
                        ),
                      )
                    : null,
                suffixIcon: widget.suffixIcon != null
                    ? Semantics(
                        button: true,
                        enabled: widget.onSuffixPressed != null,
                        label: 'Suffix icon button',
                        child: IconButton(
                          icon: AppIcon(icon: widget.suffixIcon),
                          color: widget.errorText != null
                              ? AppColors.error
                              : _isFocused
                              ? AppColors.primary
                              : _getIconColor(),
                          onPressed: widget.onSuffixPressed,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: true,
              child: AppText(
                widget.errorText!,
                variant: AppTextVariant.bodySmall,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
