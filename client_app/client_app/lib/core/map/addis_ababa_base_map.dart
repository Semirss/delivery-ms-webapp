import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

const String addisAbabaTileUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

List<Widget> addisAbabaBaseMapLayers({
  required String userAgentPackageName,
}) {
  return <Widget>[
    TileLayer(
      urlTemplate: addisAbabaTileUrlTemplate,
      userAgentPackageName: userAgentPackageName,
      keepBuffer: 8,
    ),
  ];
}
