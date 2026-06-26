import 'package:flutter/material.dart';

/// Convenience accessors for colors that must follow the active ThemeMode.
extension AppThemeColors on BuildContext {
  ThemeData get _theme => Theme.of(this);

  bool get isAppDark => _theme.brightness == Brightness.dark;

  Color get appBackground => _theme.scaffoldBackgroundColor;

  Color get appSurface => _theme.colorScheme.surface;

  Color get appSurfaceAlt => _theme.colorScheme.surfaceContainerHighest;

  Color get appBorder =>
      _theme.colorScheme.outline.withValues(alpha: isAppDark ? 0.55 : 1);

  Color get appTextPrimary => _theme.colorScheme.onSurface;

  Color get appTextSecondary =>
      _theme.colorScheme.onSurface.withValues(alpha: isAppDark ? 0.72 : 0.62);
}
