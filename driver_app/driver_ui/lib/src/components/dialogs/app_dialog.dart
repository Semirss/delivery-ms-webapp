import "../common/app_icon.dart";
import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_motion.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_radius.dart';
import '../../config/constants/app_shadows.dart';
import '../../config/theme/app_typography.dart';
import '../buttons/app_button.dart';

/// Enum defining the size variants of AppDialog
enum AppDialogSize {
  /// Small dialog (max width: 320px)
  small,

  /// Medium dialog (max width: 400px)
  medium,

  /// Large dialog (max width: 500px)
  large,
}

/// Enum defining the variant types of AppDialog
enum AppDialogVariant {
  /// Default dialog
  default_,

  /// Alert dialog with warning styling
  alert,

  /// Confirmation dialog
  confirmation,

  /// Info dialog with info styling
  info,

  /// Success dialog with success styling
  success,

  /// Warning dialog with warning styling
  warning,

  /// Error dialog with error styling
  error,

  /// Destructive dialog for dangerous actions
  destructive,
}

/// Enum defining dialog animation types
enum AppDialogAnimation {
  /// Fade animation
  fade,

  /// Scale animation
  scale,

  /// Slide from top
  slideTop,

  /// Slide from bottom
  slideBottom,

  /// Slide from left
  slideLeft,

  /// Slide from right
  slideRight,

  /// No animation
  none,
}

/// A comprehensive and rich dialog component with extensive customization options.
///
/// AppDialog provides a feature-rich dialog interface with support for
/// different sizes, variants, animations, rich content, custom styling, and actions.
///
/// Example usage:
/// ```dart
/// AppDialog.show(
///   context: context,
///   title: 'Delete Item',
///   content: 'Are you sure you want to delete this item? This action cannot be undone.',
///   variant: AppDialogVariant.destructive,
///   primaryAction: AppDialogAction(
///     label: 'Delete',
///     onPressed: () => Navigator.pop(context, true),
///     variant: AppButtonVariant.primary,
///   ),
///   secondaryAction: AppDialogAction(
///     label: 'Cancel',
///     onPressed: () => Navigator.pop(context, false),
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  /// Title displayed in the dialog header
  final String? title;

  /// Subtitle displayed below the title
  final String? subtitle;

  /// Main content of the dialog
  final Widget? content;

  /// Text content (alternative to widget content)
  final String? contentText;

  /// Icon displayed in the dialog
  final dynamic icon;

  /// Custom icon color
  final Color? iconColor;

  /// Size variant of the dialog
  final AppDialogSize size;

  /// Visual variant of the dialog
  final AppDialogVariant variant;

  /// Animation type for dialog appearance
  final AppDialogAnimation animation;

  /// Primary action button
  final AppDialogAction? primaryAction;

  /// Secondary action button
  final AppDialogAction? secondaryAction;

  /// Additional action buttons
  final List<AppDialogAction>? additionalActions;

  /// Whether to show close button
  final bool showCloseButton;

  /// Whether the dialog can be dismissed by tapping outside
  final bool barrierDismissible;

  /// Backdrop color
  final Color? barrierColor;

  /// Custom header widget
  final Widget? customHeader;

  /// Custom footer widget
  final Widget? customFooter;

  /// Whether content is scrollable
  final bool scrollable;

  /// Maximum height of the dialog content
  final double? maxHeight;

  /// Animation duration
  final Duration animationDuration;

  /// Whether to show divider between header and content
  final bool showHeaderDivider;

  /// Whether to show divider between content and footer
  final bool showFooterDivider;

  /// Padding for the dialog content
  final EdgeInsets? contentPadding;

  /// Background color of the dialog
  final Color? backgroundColor;

  /// Border radius of the dialog
  final BorderRadius? borderRadius;

  /// Whether to center the dialog
  final bool centerDialog;

  /// Custom width
  final double? width;

  /// Custom height
  final double? height;

  /// Whether to show icon in a colored container
  final bool showIconContainer;

  /// Icon container size
  final double? iconSize;

  /// Whether to show title in header
  final bool showTitle;

  /// Custom title widget
  final Widget? customTitle;

  /// Whether to show subtitle
  final bool showSubtitle;

  /// Rich text content with formatting support
  final List<TextSpan>? richContent;

  /// Whether to show loading indicator
  final bool isLoading;

  /// Loading indicator widget
  final Widget? loadingWidget;

  /// Whether to show progress indicator
  final bool showProgress;

  /// Progress value (0.0 to 1.0)
  final double? progressValue;

  /// Progress label
  final String? progressLabel;

  const AppDialog({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.contentText,
    this.icon,
    this.iconColor,
    this.size = AppDialogSize.medium,
    this.variant = AppDialogVariant.default_,
    this.animation = AppDialogAnimation.scale,
    this.primaryAction,
    this.secondaryAction,
    this.additionalActions,
    this.showCloseButton = true,
    this.barrierDismissible = true,
    this.barrierColor,
    this.customHeader,
    this.customFooter,
    this.scrollable = true,
    this.maxHeight,
    this.animationDuration = AppMotion.dialog,
    this.showHeaderDivider = true,
    this.showFooterDivider = true,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
    this.centerDialog = true,
    this.width,
    this.height,
    this.showIconContainer = true,
    this.iconSize,
    this.showTitle = true,
    this.customTitle,
    this.showSubtitle = true,
    this.richContent,
    this.isLoading = false,
    this.loadingWidget,
    this.showProgress = false,
    this.progressValue,
    this.progressLabel,
  });

  /// Shows the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? subtitle,
    Widget? content,
    String? contentText,
    dynamic icon,
    Color? iconColor,
    AppDialogSize size = AppDialogSize.medium,
    AppDialogVariant variant = AppDialogVariant.default_,
    AppDialogAnimation animation = AppDialogAnimation.scale,
    AppDialogAction? primaryAction,
    AppDialogAction? secondaryAction,
    List<AppDialogAction>? additionalActions,
    bool showCloseButton = true,
    bool barrierDismissible = true,
    Color? barrierColor,
    Widget? customHeader,
    Widget? customFooter,
    bool scrollable = true,
    double? maxHeight,
    Duration animationDuration = AppMotion.dialog,
    bool showHeaderDivider = true,
    bool showFooterDivider = true,
    EdgeInsets? contentPadding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    bool centerDialog = true,
    double? width,
    double? height,
    bool showIconContainer = true,
    double? iconSize,
    bool showTitle = true,
    Widget? customTitle,
    bool showSubtitle = true,
    List<TextSpan>? richContent,
    bool isLoading = false,
    Widget? loadingWidget,
    bool showProgress = false,
    double? progressValue,
    String? progressLabel,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: 'Dialog',
      transitionDuration: animationDuration,
      useRootNavigator:
          true, // Use root navigator to prevent conflicts with GoRouter
      pageBuilder: (context, anim, secondaryAnimation) {
        return AppDialog(
          title: title,
          subtitle: subtitle,
          content: content,
          contentText: contentText,
          icon: icon,
          iconColor: iconColor,
          size: size,
          variant: variant,
          animation: animation,
          primaryAction: primaryAction,
          secondaryAction: secondaryAction,
          additionalActions: additionalActions,
          showCloseButton: showCloseButton,
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
          centerDialog: centerDialog,
          width: width,
          height: height,
          showIconContainer: showIconContainer,
          iconSize: iconSize,
          showTitle: showTitle,
          customTitle: customTitle,
          showSubtitle: showSubtitle,
          richContent: richContent,
          isLoading: isLoading,
          loadingWidget: loadingWidget,
          showProgress: showProgress,
          progressValue: progressValue,
          progressLabel: progressLabel,
        );
      },
      transitionBuilder: (context, anim, secondaryAnimation, child) {
        return _buildAnimation(
          animation: anim,
          animationType: animation,
          child: child,
        );
      },
    );
  }

  /// Shows an alert dialog
  static Future<T?> alert<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.warning_rounded,
    AppDialogAction? primaryAction,
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.alert,
      size: size,
      primaryAction:
          primaryAction ??
          AppDialogAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Shows a confirmation dialog
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.help_outline_rounded,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
    AppDialogSize size = AppDialogSize.small,
    AppDialogVariant variant = AppDialogVariant.confirmation,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: variant,
      size: size,
      primaryAction: AppDialogAction(
        label: confirmLabel,
        onPressed: () {
          // Use rootNavigator to ensure dialog pops from root navigator
          // This prevents conflicts with GoRouter navigation
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop(true);
          } else {
            // If can't pop, just close the dialog using the context
            Navigator.of(context).pop(true);
          }
        },
        variant: confirmVariant,
      ),
      secondaryAction: AppDialogAction(
        label: cancelLabel,
        onPressed: () {
          // Use rootNavigator to ensure dialog pops from root navigator
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop(false);
          } else {
            Navigator.of(context).pop(false);
          }
        },
        variant: AppButtonVariant.secondary,
      ),
    );
  }

  /// Shows an info dialog
  static Future<T?> info<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.info_outline_rounded,
    AppDialogAction? primaryAction,
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.info,
      size: size,
      primaryAction:
          primaryAction ??
          AppDialogAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Shows a success dialog
  static Future<T?> success<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.check_circle_outline_rounded,
    AppDialogAction? primaryAction,
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.success,
      size: size,
      primaryAction:
          primaryAction ??
          AppDialogAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Shows a warning dialog
  static Future<T?> warning<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.warning_amber_rounded,
    AppDialogAction? primaryAction,
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.warning,
      size: size,
      primaryAction:
          primaryAction ??
          AppDialogAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Shows an error dialog
  static Future<T?> error<T>({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.error_outline_rounded,
    AppDialogAction? primaryAction,
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<T>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.error,
      size: size,
      primaryAction:
          primaryAction ??
          AppDialogAction(
            label: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
    );
  }

  /// Shows a destructive dialog
  static Future<bool?> destructive({
    required BuildContext context,
    required String title,
    String? content,
    String? contentText,
    dynamic icon = Icons.delete_outline_rounded,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    AppDialogSize size = AppDialogSize.small,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: content != null ? AppText(content) : null,
      contentText: contentText,
      icon: icon,
      variant: AppDialogVariant.destructive,
      size: size,
      primaryAction: AppDialogAction(
        label: confirmLabel,
        onPressed: () {
          // Use rootNavigator to ensure dialog pops from root navigator
          // This prevents conflicts with GoRouter navigation
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop(true);
          } else {
            Navigator.of(context).pop(true);
          }
        },
        variant: AppButtonVariant.primary,
        customForegroundColor: Colors.white,
        customBackgroundColor: AppColors.error,
      ),
      secondaryAction: AppDialogAction(
        label: cancelLabel,
        onPressed: () {
          // Use rootNavigator to ensure dialog pops from root navigator
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop(false);
          } else {
            Navigator.of(context).pop(false);
          }
        },
        variant: AppButtonVariant.secondary,
      ),
    );
  }

  /// Returns the max width based on size
  double get _maxWidth {
    if (width != null) return width!;
    switch (size) {
      case AppDialogSize.small:
        return 320;
      case AppDialogSize.medium:
        return 400;
      case AppDialogSize.large:
        return 500;
    }
  }

  /// Returns the icon color based on variant
  Color get _iconColor {
    if (iconColor != null) return iconColor!;
    switch (variant) {
      case AppDialogVariant.default_:
        return AppColors.primary;
      case AppDialogVariant.alert:
      case AppDialogVariant.warning:
        return AppColors.warning;
      case AppDialogVariant.confirmation:
        return AppColors.info;
      case AppDialogVariant.info:
        return AppColors.info;
      case AppDialogVariant.success:
        return AppColors.success;
      case AppDialogVariant.error:
      case AppDialogVariant.destructive:
        return AppColors.error;
    }
  }

  /// Returns the background color
  Color get _backgroundColor {
    return backgroundColor ?? AppColors.surface;
  }

  /// Returns the border radius
  BorderRadius get _borderRadius {
    if (borderRadius != null) return borderRadius!;
    return BorderRadius.circular(AppRadius.lg);
  }

  /// Returns the padding based on size
  EdgeInsets get _padding {
    switch (size) {
      case AppDialogSize.small:
        return const EdgeInsets.all(AppSpacing.md);
      case AppDialogSize.medium:
        return const EdgeInsets.all(AppSpacing.lg);
      case AppDialogSize.large:
        return const EdgeInsets.all(AppSpacing.xl);
    }
  }

  /// Returns the icon size
  double get _iconSize {
    return iconSize ?? 24;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final effectiveMaxWidth = (width ?? _maxWidth).clamp(
      0.0,
      screenSize.width * 0.9,
    );
    final effectiveMaxHeight = maxHeight ?? (screenSize.height * 0.8);

    final dialogContent = Material(
      type: MaterialType.transparency,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        label: title ?? 'Dialog',
        explicitChildNodes: true,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: effectiveMaxWidth,
            maxHeight: effectiveMaxHeight,
            minHeight: height ?? 0,
          ),
          width: width != null
              ? width!.clamp(0.0, screenSize.width * 0.9)
              : null,
          height: height,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: _borderRadius,
            boxShadow: AppShadows.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              if (customHeader != null)
                customHeader!
              else if (title != null || icon != null || customTitle != null)
                _buildHeader(context),

              // Divider
              if (showHeaderDivider &&
                  (title != null || icon != null || customTitle != null) &&
                  (content != null ||
                      contentText != null ||
                      richContent != null ||
                      customFooter != null ||
                      primaryAction != null ||
                      secondaryAction != null ||
                      isLoading ||
                      showProgress))
                const Divider(height: 1, color: AppColors.border),

              // Loading indicator
              if (isLoading) Flexible(child: _buildLoading(context)),

              // Progress indicator
              if (showProgress && !isLoading)
                Flexible(child: _buildProgress(context)),

              // Content
              if (!isLoading && !showProgress)
                if (content != null ||
                    contentText != null ||
                    richContent != null)
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            maxHeight ??
                            MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: _buildContent(context),
                    ),
                  ),

              // Divider
              if (showFooterDivider &&
                  (primaryAction != null ||
                      secondaryAction != null ||
                      additionalActions != null ||
                      customFooter != null) &&
                  (content != null ||
                      contentText != null ||
                      richContent != null ||
                      isLoading ||
                      showProgress))
                const Divider(height: 1, color: AppColors.border),

              // Footer
              if (customFooter != null)
                customFooter!
              else if (primaryAction != null ||
                  secondaryAction != null ||
                  additionalActions != null)
                _buildFooter(context),
            ],
          ),
        ),
      ),
    );

    if (centerDialog) {
      return Center(child: dialogContent);
    }

    return dialogContent;
  }

  /// Builds the animation widget
  static Widget _buildAnimation({
    required Animation<double> animation,
    required AppDialogAnimation animationType,
    required Widget child,
  }) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );

    switch (animationType) {
      case AppDialogAnimation.fade:
        return FadeTransition(opacity: curvedAnimation, child: child);
      case AppDialogAnimation.scale:
        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.98,
              end: 1.0,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      case AppDialogAnimation.slideTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case AppDialogAnimation.slideBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case AppDialogAnimation.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case AppDialogAnimation.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      case AppDialogAnimation.none:
        return child;
    }
  }

  /// Builds the header widget
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: _padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          if (icon != null) ...[
            if (showIconContainer)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: AppIcon(icon: icon, color: _iconColor, size: _iconSize),
              )
            else
              AppIcon(icon: icon, color: _iconColor, size: _iconSize),
            const SizedBox(width: AppSpacing.md),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (customTitle != null)
                  Flexible(child: customTitle!)
                else if (showTitle && title != null)
                  AppText(
                    title!,
                    variant: AppTextVariant.heading3,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                if (showSubtitle && subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    subtitle!,
                    variant: AppTextVariant.bodySmall,
                    color: AppColors.textSecondary,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),

          // Close button
          if (showCloseButton) ...[
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: 'Close dialog',
              child: IconButton(
                icon: const AppIcon(icon: Icons.close, size: 20),
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
        ],
      ),
    );
  }

  /// Builds the loading widget
  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: _padding,
      child: loadingWidget ?? const Center(child: CircularProgressIndicator()),
    );
  }

  /// Builds the progress widget
  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: _padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progressLabel != null) ...[
            AppText(
              progressLabel!,
              variant: AppTextVariant.bodySmall,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: AppColors.surfaceAlt,
            valueColor: AlwaysStoppedAnimation<Color>(_iconColor),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppText(
              '${(progressValue! * 100).toStringAsFixed(0)}%',
              variant: AppTextVariant.bodySmall,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the content widget
  Widget _buildContent(BuildContext context) {
    Widget? contentWidget;

    if (content != null) {
      contentWidget = content;
    } else if (richContent != null) {
      contentWidget = AppText.rich(
        TextSpan(
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          children: richContent,
        ),
        variant: AppTextVariant.bodyMedium,
      );
    } else if (contentText != null) {
      contentWidget = AppText(
        contentText!,
        variant: AppTextVariant.bodyMedium,
        color: AppColors.textPrimary,
      );
    } else {
      contentWidget = const SizedBox.shrink();
    }

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

/// Represents an action button in AppDialog
class AppDialogAction {
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

  /// Custom background color
  final Color? customBackgroundColor;

  /// Custom foreground color
  final Color? customForegroundColor;

  const AppDialogAction({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.enabled = true,
    this.icon,
    this.customBackgroundColor,
    this.customForegroundColor,
  });

  /// Builds the button widget
  Widget _buildButton(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: enabled ? onPressed : null,
      variant: variant,
      size: size,
      icon: icon,
      customBackgroundColor: customBackgroundColor,
      customForegroundColor: customForegroundColor,
    );
  }
}
