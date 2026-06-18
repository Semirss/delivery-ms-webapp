import 'package:flutter/material.dart';
import '../typography/app_text.dart';
import '../../config/constants/app_colors.dart';
import '../../config/theme/app_typography.dart';

/// Enum defining the size variants of AppAppBar
enum AppAppBarSize { small, medium, large }

/// A customizable app bar component with consistent styling.
///
/// AppAppBar provides a flexible app bar with support for
/// different sizes, colors, and actions following the App UI design system.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title widget to display in the app bar
  final Widget? title;

  /// The title text to display (alternative to title widget)
  final String? titleText;

  /// Leading widget (typically a back button or menu icon)
  final Widget? leading;

  /// List of action widgets to display on the right
  final List<Widget>? actions;

  /// Background color of the app bar
  final Color? backgroundColor;

  /// Foreground color for text and icons
  final Color? foregroundColor;

  /// Whether to show elevation shadow
  final bool elevated;

  /// Custom elevation value
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Bottom widget (typically a TabBar)
  final PreferredSizeWidget? bottom;

  /// Size variant of the app bar
  final AppAppBarSize size;

  /// Whether to show a back button automatically
  final bool automaticallyImplyLeading;

  /// Custom height
  final double? height;

  /// Flexible space widget
  final Widget? flexibleSpace;

  const AppAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevated = true,
    this.elevation,
    this.centerTitle = false,
    this.bottom,
    this.size = AppAppBarSize.medium,
    this.automaticallyImplyLeading = true,
    this.height,
    this.flexibleSpace,
  });

  /// Creates a primary app bar
  factory AppAppBar.primary({
    Key? key,
    Widget? title,
    String? titleText,
    Widget? leading,
    List<Widget>? actions,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
    AppAppBarSize size = AppAppBarSize.medium,
  }) {
    return AppAppBar(
      key: key,
      title: title,
      titleText: titleText,
      leading: leading,
      actions: actions,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: centerTitle,
      bottom: bottom,
      size: size,
    );
  }

  /// Creates a transparent app bar
  factory AppAppBar.transparent({
    Key? key,
    Widget? title,
    String? titleText,
    Widget? leading,
    List<Widget>? actions,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
    AppAppBarSize size = AppAppBarSize.medium,
  }) {
    return AppAppBar(
      key: key,
      title: title,
      titleText: titleText,
      leading: leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      elevated: false,
      centerTitle: centerTitle,
      bottom: bottom,
      size: size,
    );
  }

  /// Creates a surface app bar
  factory AppAppBar.surface({
    Key? key,
    Widget? title,
    String? titleText,
    Widget? leading,
    List<Widget>? actions,
    bool centerTitle = false,
    PreferredSizeWidget? bottom,
    AppAppBarSize size = AppAppBarSize.medium,
  }) {
    return AppAppBar(
      key: key,
      title: title,
      titleText: titleText,
      leading: leading,
      actions: actions,
      backgroundColor: AppColors.surface,
      centerTitle: centerTitle,
      bottom: bottom,
      size: size,
    );
  }

  double get _height {
    if (height != null) return height!;
    switch (size) {
      case AppAppBarSize.small:
        return 48.0;
      case AppAppBarSize.medium:
        return 56.0;
      case AppAppBarSize.large:
        return 64.0;
    }
  }

  TextStyle get _titleStyle {
    switch (size) {
      case AppAppBarSize.small:
        return AppTypography.labelMedium;
      case AppAppBarSize.medium:
        return AppTypography.labelLarge;
      case AppAppBarSize.large:
        return AppTypography.heading3;
    }
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(_height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final defaultBackgroundColor =
        backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);

    final defaultForegroundColor =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    Widget? titleWidget;
    if (title != null) {
      titleWidget = title;
    } else if (titleText != null) {
      AppTextVariant variant;
      switch (size) {
        case AppAppBarSize.small:
          variant = AppTextVariant.labelMedium;
          break;
        case AppAppBarSize.medium:
          variant = AppTextVariant.labelLarge;
          break;
        case AppAppBarSize.large:
          variant = AppTextVariant.heading3;
          break;
      }

      titleWidget = AppText(
        titleText!,
        variant: variant,
        color: defaultForegroundColor,
      );
    }

    return AppBar(
      title: titleWidget,
      leading: leading,
      actions: actions,
      backgroundColor: defaultBackgroundColor,
      foregroundColor: defaultForegroundColor,
      elevation: elevated ? (elevation ?? 2.0) : 0,
      centerTitle: centerTitle,
      bottom: bottom,
      automaticallyImplyLeading: automaticallyImplyLeading,
      toolbarHeight: _height,
      flexibleSpace: flexibleSpace,
      shadowColor: elevated ? Colors.black.withValues(alpha: 0.1) : null,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: defaultForegroundColor),
      actionsIconTheme: IconThemeData(color: defaultForegroundColor),
    );
  }
}

/// A sliver app bar component with scroll effects.
///
/// AppSliverAppBar provides a collapsible app bar that integrates
/// with scrollable content.
class AppSliverAppBar extends StatelessWidget {
  /// The title widget to display in the app bar
  final Widget? title;

  /// The title text to display (alternative to title widget)
  final String? titleText;

  /// Leading widget (typically a back button or menu icon)
  final Widget? leading;

  /// List of action widgets to display on the right
  final List<Widget>? actions;

  /// Background color of the app bar
  final Color? backgroundColor;

  /// Foreground color for text and icons
  final Color? foregroundColor;

  /// Whether the app bar should remain visible at the top
  final bool pinned;

  /// Whether the app bar should float above the content
  final bool floating;

  /// Whether the app bar should snap into view
  final bool snap;

  /// Expanded height when fully expanded
  final double? expandedHeight;

  /// Collapsed height
  final double? collapsedHeight;

  /// Flexible space widget (typically for background images)
  final Widget? flexibleSpace;

  /// Bottom widget (typically a TabBar)
  final PreferredSizeWidget? bottom;

  /// Whether to center the title
  final bool centerTitle;

  const AppSliverAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.collapsedHeight,
    this.flexibleSpace,
    this.bottom,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final defaultBackgroundColor =
        backgroundColor ??
        theme.appBarTheme.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);

    final defaultForegroundColor =
        foregroundColor ??
        theme.appBarTheme.foregroundColor ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    Widget? titleWidget;
    if (title != null) {
      titleWidget = title;
    } else if (titleText != null) {
      titleWidget = AppText(
        titleText!,
        variant: AppTextVariant.labelLarge,
        color: defaultForegroundColor,
      );
    }

    return SliverAppBar(
      title: titleWidget,
      leading: leading,
      actions: actions,
      backgroundColor: defaultBackgroundColor,
      foregroundColor: defaultForegroundColor,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight ?? 200.0,
      collapsedHeight: collapsedHeight,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      centerTitle: centerTitle,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: defaultForegroundColor),
      actionsIconTheme: IconThemeData(color: defaultForegroundColor),
    );
  }
}
