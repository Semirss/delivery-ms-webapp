import 'package:flutter/material.dart';
import '../../../app_ui.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';

/// Enum defining the size variants of AppModal (deprecated - use heightPercentage instead)
@Deprecated('Use heightPercentage parameter instead')
enum AppModalSize {
  /// Small modal (40% of screen height)
  small,

  /// Medium modal (60% of screen height)
  medium,

  /// Large modal (80% of screen height)
  large,

  /// Extra large modal (95% of screen height)
  extraLarge,

  /// Fullscreen modal (100% of screen height)
  fullscreen,
}

/// Enum defining the variant types of AppModal
enum AppModalVariant {
  /// Default modal
  default_,

  /// Alert modal with warning styling
  alert,

  /// Confirmation modal
  confirmation,

  /// Info modal with info styling
  info,

  /// Success modal with success styling
  success,

  /// Warning modal with warning styling
  warning,

  /// Error modal with error styling
  error,
}

/// A comprehensive and customizable modal/dialog component.
///
/// AppModal provides a rich modal interface with support for
/// different sizes, variants, animations, custom content, and actions.
///
/// Example usage:
/// ```dart
/// AppModal.show(
///   context: context,
///   title: 'Confirm Action',
///   content: 'Are you sure you want to proceed?',
///   variant: AppModalVariant.confirmation,
///   primaryAction: AppModalAction(
///     label: 'Confirm',
///     onPressed: () => Navigator.pop(context),
///   ),
///   secondaryAction: AppModalAction(
///     label: 'Cancel',
///     onPressed: () => Navigator.pop(context),
///   ),
/// );
/// ```
class AppModal extends StatelessWidget {
  /// Title displayed in the modal header
  final String? title;

  /// Subtitle displayed below the title
  final String? subtitle;

  /// Main content of the modal
  final Widget? content;

  /// Text content (alternative to widget content)
  final String? contentText;

  /// Icon displayed in the header
  final dynamic icon;

  /// Custom icon color
  final Color? iconColor;

  /// Size variant of the modal (deprecated - use heightPercentage instead)
  @Deprecated('Use heightPercentage parameter instead')
  final AppModalSize? size;

  /// Height as a percentage of screen height (0.0 to 1.0)
  /// For example: 0.5 = 50%, 0.8 = 80%, 1.0 = 100%
  final double? heightPercentage;

  /// Visual variant of the modal
  final AppModalVariant variant;

  /// Primary action button
  final AppModalAction? primaryAction;

  /// Secondary action button
  final AppModalAction? secondaryAction;

  /// Additional action buttons
  final List<AppModalAction>? additionalActions;

  /// Whether to show close button
  final bool showCloseButton;

  /// Whether the modal can be dismissed by tapping outside
  final bool dismissible;

  /// Whether the modal can be dismissed by pressing back button
  final bool barrierDismissible;

  /// Backdrop color
  final Color? barrierColor;

  /// Custom header widget
  final Widget? customHeader;

  /// Custom footer widget
  final Widget? customFooter;

  /// Whether content is scrollable
  final bool scrollable;

  /// Maximum height of the modal content
  final double? maxHeight;

  /// Animation duration
  final Duration animationDuration;

  /// Whether to show divider between header and content
  final bool showHeaderDivider;

  /// Whether to show divider between content and footer
  final bool showFooterDivider;

  /// Padding for the modal content
  final EdgeInsets? contentPadding;

  /// Background color of the modal
  final Color? backgroundColor;

  /// Border radius of the modal
  final BorderRadius? borderRadius;

  const AppModal({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.contentText,
    this.icon,
    this.iconColor,
    @Deprecated('Use heightPercentage parameter instead') this.size,
    this.heightPercentage,
    this.variant = AppModalVariant.default_,
    this.primaryAction,
    this.secondaryAction,
    this.additionalActions,
    this.showCloseButton = true,
    this.dismissible = true,
    this.barrierDismissible = true,
    this.barrierColor,
    this.customHeader,
    this.customFooter,
    this.scrollable = true,
    this.maxHeight,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showHeaderDivider = true,
    this.showFooterDivider = true,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
  }) : assert(
         heightPercentage == null ||
             (heightPercentage >= 0.0 && heightPercentage <= 1.0),
         'heightPercentage must be between 0.0 and 1.0',
       );

  /// Shows the modal as a bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    Widget? content,
    String? contentText,
    dynamic icon,
    Color? iconColor,
    @Deprecated('Use heightPercentage parameter instead') AppModalSize? size,
    double? heightPercentage,
    AppModalVariant variant = AppModalVariant.default_,
    AppModalAction? primaryAction,
    AppModalAction? secondaryAction,
    List<AppModalAction>? additionalActions,
    bool showCloseButton = true,
    bool dismissible = true,
    bool barrierDismissible = true,
    Color? barrierColor,
    Widget? customHeader,
    Widget? customFooter,
    bool scrollable = true,
    double? maxHeight,
    Duration animationDuration = const Duration(milliseconds: 300),
    bool showHeaderDivider = true,
    bool showFooterDivider = true,
    EdgeInsets? contentPadding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool showDragHandle = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isDismissible: barrierDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      transitionAnimationController: null,
      builder: (context) {
        return AppModal(
          title: title,
          subtitle: subtitle,
          content: content,
          contentText: contentText,
          icon: icon,
          iconColor: iconColor,
          size: size,
          heightPercentage: heightPercentage,
          variant: variant,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
          additionalActions: additionalActions,
          showCloseButton: showCloseButton,
          dismissible: dismissible,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          customHeader: customHeader,
          customFooter: customFooter,
          scrollable: scrollable,
          maxHeight: maxHeight,
          animationDuration: animationDuration,
          showHeaderDivider: showHeaderDivider,
          showFooterDivider: showFooterDivider,
          contentPadding: contentPadding,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
        );
      },
    );
  }

  /// Shows the modal with a DraggableScrollableSheet
  static Future<T?> showScrollable<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) builder,
    String? title,
    String? subtitle,
    double heightPercentage = 0.9,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isDismissible: barrierDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black54,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: heightPercentage,
          minChildSize: 0.2,
          maxChildSize: heightPercentage,
          expand: false,
          builder: (context, scrollController) {
            return AppModal(
              title: title,
              subtitle: subtitle,
              showCloseButton: showCloseButton,
              scrollable: false, // Scrollability is handled by the sheet
              content: builder(context, scrollController),
            );
          },
        );
      },
    );
  }

  /// Shows an alert modal
  static Future<T?> alert<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.warning_rounded,
    AppModalAction? primaryAction,
    double heightPercentage = 0.4,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.alert,
      heightPercentage: heightPercentage,
      primaryAction:
          primaryAction ??
          AppModalAction(
            label: 'OK',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
    );
  }

  /// Shows a confirmation modal
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.help_outline_rounded,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    double heightPercentage = 0.4,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.confirmation,
      heightPercentage: heightPercentage,
      primaryAction: AppModalAction(
        label: confirmLabel,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        variant: AppButtonVariant.primary,
      ),
      secondaryAction: AppModalAction(
        label: cancelLabel,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        variant: AppButtonVariant.secondary,
      ),
    );
  }

  /// Shows an info modal
  static Future<T?> info<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.info_outline_rounded,
    AppModalAction? primaryAction,
    double heightPercentage = 0.4,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.info,
      heightPercentage: heightPercentage,
      primaryAction:
          primaryAction ??
          AppModalAction(
            label: 'OK',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
    );
  }

  /// Shows a success modal
  static Future<T?> success<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.check_circle_outline_rounded,
    AppModalAction? primaryAction,
    double heightPercentage = 0.4,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.success,
      heightPercentage: heightPercentage,
      primaryAction:
          primaryAction ??
          AppModalAction(
            label: 'OK',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
    );
  }

  /// Shows a warning modal
  static Future<T?> warning<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.warning_amber_rounded,
    AppModalAction? primaryAction,
    double heightPercentage = 0.4,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.warning,
      heightPercentage: heightPercentage,
      primaryAction:
          primaryAction ??
          AppModalAction(
            label: 'OK',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
    );
  }

  /// Shows an error modal
  static Future<T?> error<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.error_outline_rounded,
    AppModalAction? primaryAction,
    double heightPercentage = 0.4,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppModalVariant.error,
      heightPercentage: heightPercentage,
      primaryAction:
          primaryAction ??
          AppModalAction(
            label: 'OK',
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          ),
    );
  }

  /// Returns the icon color based on variant
  Color get _iconColor {
    if (iconColor != null) return iconColor!;
    switch (variant) {
      case AppModalVariant.default_:
        return AppColors.primary;
      case AppModalVariant.alert:
      case AppModalVariant.warning:
        return AppColors.warning;
      case AppModalVariant.confirmation:
        return AppColors.info;
      case AppModalVariant.info:
        return AppColors.info;
      case AppModalVariant.success:
        return AppColors.success;
      case AppModalVariant.error:
        return AppColors.error;
    }
  }

  /// Returns the background color
  Color get _backgroundColor {
    return backgroundColor ?? AppColors.surface;
  }

  /// Returns the padding based on height percentage
  EdgeInsets get _padding {
    final percentage = _effectiveHeightPercentage;

    if (percentage <= 0.4) {
      return const EdgeInsets.all(AppSpacing.lg);
    } else if (percentage <= 0.6) {
      return const EdgeInsets.all(AppSpacing.xl);
    } else if (percentage < 1.0) {
      return const EdgeInsets.all(AppSpacing.xl * 1.5);
    } else {
      return const EdgeInsets.all(AppSpacing.xl);
    }
  }

  /// Returns the effective height percentage
  double get _effectiveHeightPercentage {
    // If heightPercentage is provided, use it
    if (heightPercentage != null) {
      return heightPercentage!;
    }

    // Otherwise, fall back to size enum (for backward compatibility)
    if (size != null) {
      switch (size!) {
        case AppModalSize.small:
          return 0.4; // 40%
        case AppModalSize.medium:
          return 0.6; // 60%
        case AppModalSize.large:
          return 0.8; // 80%
        case AppModalSize.extraLarge:
          return 0.95; // 95%
        case AppModalSize.fullscreen:
          return 1.0; // 100%
      }
    }

    // Default to medium size
    return 0.6;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final effectiveMaxHeight =
        maxHeight ?? (screenSize.height * _effectiveHeightPercentage);

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(maxHeight: effectiveMaxHeight),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: _effectiveHeightPercentage >= 1.0
              ? BorderRadius.zero
              : const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            _buildDragHandle(context),

            // Header
            if (customHeader != null)
              customHeader!
            else if (title != null || icon != null)
              _buildHeader(context),

            // Divider
            if (showHeaderDivider &&
                (title != null || icon != null) &&
                (content != null ||
                    contentText != null ||
                    customFooter != null ||
                    primaryAction != null ||
                    secondaryAction != null))
              const Divider(height: 1, color: AppColors.border),

            // Content
            if (content != null || contentText != null)
              Flexible(child: _buildContent(context)),

            // Divider
            if (showFooterDivider &&
                (primaryAction != null ||
                    secondaryAction != null ||
                    additionalActions != null ||
                    customFooter != null) &&
                (content != null || contentText != null))
              const Divider(height: 1, color: AppColors.border),

            // Footer
            if (customFooter != null)
              customFooter!
            else if (primaryAction != null ||
                secondaryAction != null ||
                additionalActions != null)
              _buildFooter(context),

            // Bottom safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Builds the drag handle widget
  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ),
    );
  }

  /// Builds the header widget
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: _iconColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  AppText(
                    title!,
                    variant: AppTextVariant.heading3,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    subtitle!,
                    variant: AppTextVariant.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),

          // Close button
          if (showCloseButton)
            Semantics(
              button: true,
              label: 'Close modal',
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44.0,
                  minHeight: 44.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the content widget
  Widget _buildContent(BuildContext context) {
    final contentWidget =
        content ??
        (contentText != null
            ? AppText(
                contentText!,
                variant: AppTextVariant.bodyMedium,
                color: AppColors.textPrimary,
              )
            : const SizedBox.shrink());

    final padding = contentPadding ?? _padding;

    if (scrollable) {
      return SingleChildScrollView(padding: padding, child: contentWidget);
    }

    return Padding(padding: padding, child: contentWidget);
  }

  /// Builds the footer widget
  Widget _buildFooter(BuildContext context) {
    final actions = <Widget>[];

    // Additional actions (left side)
    if (additionalActions != null) {
      for (final action in additionalActions!) {
        actions.add(action._buildButton(context));
        actions.add(const SizedBox(width: AppSpacing.sm));
      }
    }

    // Secondary action
    if (secondaryAction != null) {
      actions.add(secondaryAction!._buildButton(context));
    }

    // Primary action
    if (primaryAction != null) {
      if (secondaryAction != null || additionalActions != null) {
        actions.add(const SizedBox(width: AppSpacing.sm));
      }
      actions.add(primaryAction!._buildButton(context));
    }

    return Container(
      padding: _padding,
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
    );
  }
}

/// Represents an action button in AppModal
class AppModalAction {
  /// Label text for the button
  final String label;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Button variant
  final AppButtonVariant variant;

  /// Button size
  final AppButtonSize size;

  /// Whether the button is enabled
  final bool enabled;

  /// Icon to display before the label
  final dynamic icon;

  const AppModalAction({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.enabled = true,
    this.icon,
  });

  /// Builds the button widget
  Widget _buildButton(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: enabled ? onPressed : null,
      variant: variant,
      size: size,
      icon: icon,
    );
  }
}
