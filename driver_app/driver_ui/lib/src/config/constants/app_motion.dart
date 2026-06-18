import 'package:flutter/material.dart';

/// Motion tokens for consistent animation timing and easing.
abstract class AppMotion {
  /// Short duration for micro-interactions.
  static const Duration fast = Duration(milliseconds: 160);

  /// Standard duration for UI transitions.
  static const Duration standard = Duration(milliseconds: 220);

  /// Slower duration for dialogs and overlays.
  static const Duration slow = Duration(milliseconds: 280);

  /// Default toast enter/exit duration.
  static const Duration toast = Duration(milliseconds: 180);

  /// Default dialog enter/exit duration.
  static const Duration dialog = Duration(milliseconds: 240);

  /// Standard curve for entering elements.
  static const Curve enterCurve = Curves.easeOutCubic;

  /// Standard curve for exiting elements.
  static const Curve exitCurve = Curves.easeInCubic;
}
