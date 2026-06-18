import 'package:flutter/material.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

/// Component sizing tokens for reusable UI components.
abstract class AppComponentSizes {
  // Toast
  static const double toastMaxWidth = 320.0;
  static const double toastIconSize = 18.0;
  static const double toastCloseIconSize = 16.0;
  static const double toastTitleSpacing = AppSpacing.xs;
  static const EdgeInsets toastPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
  static const EdgeInsets toastPaddingTop = EdgeInsets.only(
    top: AppSpacing.xxl,
    left: AppSpacing.md,
    right: AppSpacing.md,
  );
  static const EdgeInsets toastPaddingBottom = EdgeInsets.only(
    bottom: AppSpacing.xxl,
    left: AppSpacing.md,
    right: AppSpacing.md,
  );
  static const EdgeInsets toastPaddingCenter = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
  );
  static const double toastRadius = AppRadius.md;

  // SnackBar
  static const double snackBarIconSize = 18.0;
  static const EdgeInsets snackBarPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );
  static const EdgeInsets snackBarMargin = EdgeInsets.all(AppSpacing.md);
  static const double snackBarRadius = AppRadius.md;
}
