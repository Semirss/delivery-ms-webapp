import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class MapRepository {
  MapRepository()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 3),
        ),
      );

  final Dio _dio;

  /// Get route polyline using OSRM API
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    if (!_isValidPoint(start) || !_isValidPoint(end)) return [];

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
                final point = LatLng(latitude.toDouble(), longitude.toDouble());
                if (_isValidPoint(point)) routePoints.add(point);
              }
            }
          }
          if (routePoints.length >= 2) return routePoints;
          return _fallbackRoute(start, end);
        }
      }
      return _fallbackRoute(start, end);
    } catch (e) {
      print('Error getting route: $e');
      return _fallbackRoute(start, end);
    }
  }

  List<LatLng> _fallbackRoute(LatLng start, LatLng end) {
    if (!_isValidPoint(start) || !_isValidPoint(end)) return [];
    return <LatLng>[start, end];
  }

  bool _isValidPoint(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}
