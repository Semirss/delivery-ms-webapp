import 'package:flutter/material.dart';

/// Predefined shadow definitions for creating elevation and depth in the UI.
///
/// Provides a complete shadow scale from small to extra-large, ensuring consistent
/// elevation levels across all components. These shadows are used to create depth
/// and hierarchy in the component system.
///
/// Example usage:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.md,
///     borderRadius: BorderRadius.circular(AppRadius.lg),
///   ),
/// )
/// ```
abstract class AppShadows {
  /// Small shadow - Subtle elevation for minimal depth
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Medium shadow - Standard elevation for cards and buttons
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  /// Large shadow - Prominent elevation for modals and overlays
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 15, offset: Offset(0, 4)),
  ];

  /// Extra large shadow - Maximum elevation for floating elements
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x26000000), blurRadius: 25, offset: Offset(0, 8)),
  ];
}
