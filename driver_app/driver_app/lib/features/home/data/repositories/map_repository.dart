import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class MapRepository {
  final Dio _dio = Dio();

  /// Get route polyline using OSRM API
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          return coordinates.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting route: $e');
      return [];
    }
  }
}
