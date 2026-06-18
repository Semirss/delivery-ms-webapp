import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../common/app_icon.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_component_sizes.dart';
import '../../config/constants/app_motion.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/constants/app_shadows.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the type of toast notification
enum AppToastType { success, error, warning, info }

/// Enum defining the position of the toast
enum AppToastPosition { top, bottom, center }

/// A toast notification component for displaying temporary messages.
///
/// AppToast provides a non-intrusive way to show feedback messages
/// with different types (success, error, warning, info).
class AppToast {
  /// Shows a toast notification
  static void show({
    required BuildContext context,
    required String message,
    String? title,
    AppToastType type = AppToastType.info,
    AppToastPosition position = AppToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    dynamic icon,
    VoidCallback? onTap,
    bool dismissible = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AppToastWidget(
        message: message,
        title: title,
        type: type,
        position: position,
        backgroundColor: backgroundColor,
        icon: icon,
        onTap: onTap,
        dismissible: dismissible,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Shows a success toast
  static void success({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppToastType.success,
      duration: duration,
    );
  }

  /// Shows an error toast
  static void error({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppToastType.error,
      duration: duration,
    );
  }

  /// Shows a warning toast
  static void warning({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppToastType.warning,
      duration: duration,
    );
  }

  /// Shows an info toast
  static void info({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context: context,
      message: message,
      title: title,
      type: AppToastType.info,
      duration: duration,
    );
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AppToastType type;
  final AppToastPosition position;
  final Color? backgroundColor;
  final dynamic icon;
  final VoidCallback? onTap;
  final bool dismissible;
  final VoidCallback onDismiss;

  const _AppToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.position,
    this.backgroundColor,
    this.icon,
    this.onTap,
    required this.dismissible,
    required this.onDismiss,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppMotion.toast, vsync: this);

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    _slideAnimation = Tween<Offset>(
      begin: _getSlideOffset(),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _controller.forward();
  }

  Offset _getSlideOffset() {
    switch (widget.position) {
      case AppToastPosition.top:
        return const Offset(0, -1);
      case AppToastPosition.bottom:
        return const Offset(0, 1);
      case AppToastPosition.center:
        return const Offset(0, 0.5);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _typeColor {
    switch (widget.type) {
      case AppToastType.success:
        return AppColors.success;
      case AppToastType.error:
        return AppColors.error;
      case AppToastType.warning:
        return AppColors.warning;
      case AppToastType.info:
        return AppColors.info;
    }
  }

  dynamic get _typeIcon {
    if (widget.icon != null) return widget.icon;
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_outline;
      case AppToastType.error:
        return Icons.error_outline;
      case AppToastType.warning:
        return Icons.warning_amber_outlined;
      case AppToastType.info:
        return Icons.info_outline;
    }
  }

  Alignment get _alignment {
    switch (widget.position) {
      case AppToastPosition.top:
        return Alignment.topCenter;
      case AppToastPosition.bottom:
        return Alignment.bottomCenter;
      case AppToastPosition.center:
        return Alignment.center;
    }
  }

  EdgeInsets get _padding {
    switch (widget.position) {
      case AppToastPosition.top:
        return AppComponentSizes.toastPaddingTop;
      case AppToastPosition.bottom:
        return AppComponentSizes.toastPaddingBottom;
      case AppToastPosition.center:
        return AppComponentSizes.toastPaddingCenter;
    }
  }

  void _handleDismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: _alignment,
        child: Padding(
          padding: _padding,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: GestureDetector(
                onTap: widget.onTap,
                onHorizontalDragEnd: widget.dismissible
                    ? (details) => _handleDismiss()
                    : null,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: AppComponentSizes.toastMaxWidth,
                    ),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ?? AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(
                        AppComponentSizes.toastRadius,
                      ),
                      boxShadow: AppShadows.lg,
                    ),
                    padding: AppComponentSizes.toastPadding,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          icon: _typeIcon,
                          color: _typeColor,
                          size: AppComponentSizes.toastIconSize,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null) ...[
                                AppText(
                                  widget.title!,
                                  variant: AppTextVariant.labelSmall,
                                  color: _typeColor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(
                                  height: AppComponentSizes.toastTitleSpacing,
                                ),
                              ],
                              AppText(
                                widget.message,
                                variant: AppTextVariant.bodySmall,
                                color: AppColors.darkTextPrimary,
                                maxLines: widget.title == null ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.dismissible) ...[
                          const SizedBox(width: AppSpacing.sm),
                          GestureDetector(
                            onTap: _handleDismiss,
                            child: AppIcon(
                              icon: Icons.close,
                              size: AppComponentSizes.toastCloseIconSize,
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
