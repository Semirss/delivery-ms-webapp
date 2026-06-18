/// Standardized border radius scale for consistent rounded corners throughout the application.
///
/// Provides a complete radius scale from small to fully rounded, ensuring visual
/// consistency across all components. These values are used for border radius on
/// buttons, cards, and other components.
///
/// Example usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(AppRadius.md),
///   ),
/// )
/// ```
abstract class AppRadius {
  /// Small radius - 4.0 logical pixels
  static const double sm = 4.0;

  /// Medium radius - 8.0 logical pixels
  static const double md = 8.0;

  /// Large radius - 12.0 logical pixels
  static const double lg = 12.0;

  /// Extra large radius - 16.0 logical pixels
  static const double xl = 16.0;

  /// Extra extra large radius - 24.0 logical pixels
  static const double xxl = 24.0;

  /// Full radius - 9999.0 logical pixels (creates circular/pill shape)
  static const double full = 9999.0;
}
