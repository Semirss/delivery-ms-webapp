import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../common/app_icon.dart';
import '../../config/constants/app_colors.dart';
import '../../config/constants/app_component_sizes.dart';
import '../../config/constants/app_spacing.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the type of snackbar
enum AppSnackBarType { success, error, warning, info, neutral }

/// A snackbar component for displaying messages with actions.
///
/// AppSnackBar provides a Material Design snackbar with consistent styling
/// and support for different types and actions.
class AppSnackBar {
  /// Shows a snackbar
  static void show({
    required BuildContext context,
    required String message,
    AppSnackBarType type = AppSnackBarType.neutral,
    dynamic icon,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    bool showCloseButton = false,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          if (type != AppSnackBarType.neutral || icon != null) ...[
            AppIcon(
              icon: icon ?? _getIcon(type),
              color: _getIconColor(type),
              size: AppComponentSizes.snackBarIconSize,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: AppText(
              message,
              variant: AppTextVariant.bodySmall,
              color: Colors.white,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      padding: AppComponentSizes.snackBarPadding,
      backgroundColor: _getBackgroundColor(type),
      duration: duration,
      behavior: behavior,
      margin: behavior == SnackBarBehavior.floating
          ? AppComponentSizes.snackBarMargin
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppComponentSizes.snackBarRadius),
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : showCloseButton
          ? SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a success snackbar
  static void success({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      type: AppSnackBarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows an error snackbar
  static void error({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      type: AppSnackBarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a warning snackbar
  static void warning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      type: AppSnackBarType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows an info snackbar
  static void info({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context: context,
      message: message,
      type: AppSnackBarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static dynamic _getIcon(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_outline;
      case AppSnackBarType.error:
        return Icons.error_outline;
      case AppSnackBarType.warning:
        return Icons.warning_amber_outlined;
      case AppSnackBarType.info:
        return Icons.info_outline;
      case AppSnackBarType.neutral:
        return Icons.info_outline;
    }
  }

  static Color _getIconColor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return AppColors.success;
      case AppSnackBarType.error:
        return AppColors.error;
      case AppSnackBarType.warning:
        return AppColors.warning;
      case AppSnackBarType.info:
        return AppColors.info;
      case AppSnackBarType.neutral:
        return Colors.white;
    }
  }

  static Color _getBackgroundColor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return AppColors.success.withValues(alpha: 0.9);
      case AppSnackBarType.error:
        return AppColors.error.withValues(alpha: 0.9);
      case AppSnackBarType.warning:
        return AppColors.warning.withValues(alpha: 0.9);
      case AppSnackBarType.info:
        return AppColors.info.withValues(alpha: 0.9);
      case AppSnackBarType.neutral:
        return AppColors.darkSurface;
    }
  }
}
