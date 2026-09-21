import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

const String addisAbabaTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

List<Widget> addisAbabaBaseMapLayers({required String userAgentPackageName}) {
  return <Widget>[
    const _AddisMapLoadingBackdrop(),
    TileLayer(
      urlTemplate: addisAbabaTileUrlTemplate,
      userAgentPackageName: userAgentPackageName,
      keepBuffer: 8,
      panBuffer: 2,
      tileDisplay: const TileDisplay.fadeIn(
        duration: Duration(milliseconds: 240),
        startOpacity: 0.18,
        reloadStartOpacity: 0.72,
      ),
    ),
  ];
}

class _AddisMapLoadingBackdrop extends StatelessWidget {
  const _AddisMapLoadingBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _AddisMapLoadingPainter(
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _AddisMapLoadingPainter extends CustomPainter {
  const _AddisMapLoadingPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = dark ? const Color(0xFF18231F) : const Color(0xFFE8EEE9);
    final blockColor = dark ? const Color(0xFF22312B) : const Color(0xFFDDE6DF);
    final roadColor = dark ? const Color(0xFF35443E) : const Color(0xFFF8FAF8);
    final mainRoadColor = dark
        ? const Color(0xFF526159)
        : const Color(0xFFFFFFFF);

    canvas.drawColor(baseColor, BlendMode.src);

    final blockPaint = Paint()..color = blockColor;
    const blocks = <Rect>[
      Rect.fromLTWH(0.05, 0.08, 0.18, 0.12),
      Rect.fromLTWH(0.31, 0.05, 0.22, 0.15),
      Rect.fromLTWH(0.67, 0.08, 0.25, 0.11),
      Rect.fromLTWH(0.10, 0.33, 0.23, 0.13),
      Rect.fromLTWH(0.43, 0.29, 0.18, 0.17),
      Rect.fromLTWH(0.73, 0.34, 0.20, 0.14),
      Rect.fromLTWH(0.03, 0.62, 0.25, 0.14),
      Rect.fromLTWH(0.38, 0.58, 0.24, 0.17),
      Rect.fromLTWH(0.70, 0.65, 0.24, 0.13),
      Rect.fromLTWH(0.17, 0.84, 0.22, 0.10),
      Rect.fromLTWH(0.52, 0.82, 0.28, 0.11),
    ];
    for (final block in blocks) {
      final scaled = Rect.fromLTWH(
        block.left * size.width,
        block.top * size.height,
        block.width * size.width,
        block.height * size.height,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaled, const Radius.circular(7)),
        blockPaint,
      );
    }

    final roadPaint = Paint()
      ..color = roadColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var index = -1; index < 7; index++) {
      final y = size.height * (0.12 + index * 0.17);
      canvas.drawLine(
        Offset(-20, y),
        Offset(size.width + 20, y + size.height * 0.12),
        roadPaint,
      );
    }
    for (var index = 0; index < 6; index++) {
      final x = size.width * (0.08 + index * 0.19);
      canvas.drawLine(
        Offset(x, -20),
        Offset(x - size.width * 0.16, size.height + 20),
        roadPaint,
      );
    }

    final mainRoadPaint = Paint()
      ..color = mainRoadColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mainRoad = Path()
      ..moveTo(-20, size.height * 0.78)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.63,
        size.width * 0.48,
        size.height * 0.43,
        size.width + 20,
        size.height * 0.28,
      );
    canvas.drawPath(mainRoad, mainRoadPaint);
  }

  @override
  bool shouldRepaint(covariant _AddisMapLoadingPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
