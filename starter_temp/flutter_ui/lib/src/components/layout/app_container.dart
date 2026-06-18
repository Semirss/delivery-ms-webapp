import 'package:flutter/material.dart';

/// A container component with consistent styling from the App UI design system.
///
/// AppContainer provides a flexible container with support for padding, margin,
/// background colors, borders, and border radius using design tokens.
class AppContainer extends StatelessWidget {
  /// The child widget to display inside the container
  final Widget child;

  /// Padding inside the container
  final EdgeInsets? padding;

  /// Margin outside the container
  final EdgeInsets? margin;

  /// Background color
  final Color? backgroundColor;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double? borderWidth;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Width of the container
  final double? width;

  /// Height of the container
  final double? height;

  /// Alignment of the child within the container
  final AlignmentGeometry? alignment;

  const AppContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth ?? 1.0)
            : null,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }
}
