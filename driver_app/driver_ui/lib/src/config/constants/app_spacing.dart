/// Standardized spacing scale for consistent layout spacing throughout the application.
///
/// Provides a complete spacing scale from extra-small to extra-extra-extra-large,
/// ensuring visual consistency and proper spacing relationships. These values are
/// used for padding, margins, and gaps throughout all components.
///
/// Example usage:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(AppSpacing.lg),
///   margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
/// )
/// ```
abstract class AppSpacing {
  /// Extra small spacing - 4.0 logical pixels
  static const double xs = 4.0;

  /// Small spacing - 8.0 logical pixels
  static const double sm = 8.0;

  /// Medium spacing - 12.0 logical pixels
  static const double md = 12.0;

  /// Large spacing - 16.0 logical pixels
  static const double lg = 16.0;

  /// Extra large spacing - 20.0 logical pixels
  static const double xl = 20.0;

  /// Extra extra large spacing - 24.0 logical pixels
  static const double xxl = 24.0;

  /// Extra extra extra large spacing - 32.0 logical pixels
  static const double xxxl = 32.0;
}
