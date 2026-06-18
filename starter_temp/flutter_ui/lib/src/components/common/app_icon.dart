import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcon extends StatelessWidget {
  final dynamic icon;
  final double? size;
  final Color? color;

  const AppIcon({super.key, required this.icon, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();

    if (icon is IconData) {
      return Icon(icon as IconData, size: size, color: color);
    }

    if (icon is String) {
      final String iconPath = icon as String;
      if (iconPath.endsWith('.svg')) {
        return SvgPicture.asset(
          iconPath,
          width: size,
          height: size,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
        );
      } else {
        return Image.asset(iconPath, width: size, height: size, color: color);
      }
    }

    if (icon is Widget) {
      return icon as Widget;
    }

    return const SizedBox.shrink();
  }
}
