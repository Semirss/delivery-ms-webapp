import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class MapRepository {
  final Dio _dio = Dio();

  /// Get route polyline using OSRM API
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?overview=full&geometries=geojson';
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final routes = data?['routes'];
        if (routes is List && routes.isNotEmpty) {
          final route = routes.first;
          if (route is! Map<String, dynamic>) return [];

          final geometry = route['geometry'];
          if (geometry is! Map<String, dynamic>) return [];

          final coordinates = geometry['coordinates'];
          if (coordinates is! List) return [];

          final routePoints = <LatLng>[];
          for (final coordinate in coordinates) {
            if (coordinate is List && coordinate.length >= 2) {
              final longitude = coordinate[0];
              final latitude = coordinate[1];
              if (longitude is num && latitude is num) {
                routePoints.add(
                  LatLng(latitude.toDouble(), longitude.toDouble()),
                );
              }
            }
          }
          return routePoints;
        }
      }
      return [];
    } catch (e) {
      print('Error getting route: $e');
      return [];
    }
  }
}
