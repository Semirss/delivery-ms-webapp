import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class MapPlace {
  final String displayName;
  final LatLng location;

  MapPlace({required this.displayName, required this.location});
}

class MapRoute {
  final List<LatLng> points;
  final double distanceKm;

  const MapRoute({required this.points, required this.distanceKm});
}

class MapRepository {
  final Dio _dio = Dio();
  static const Distance _distance = Distance();

  /// Search address using OpenStreetMap Nominatim API
  Future<List<MapPlace>> searchAddress(String query) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
        options: Options(
          headers: {
            'User-Agent': 'MotoBikeClient/1.0', // Required by Nominatim policy
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data ?? <dynamic>[];
        return data.map((item) {
          final place = Map<String, dynamic>.from(item as Map);
          return MapPlace(
            displayName: place['display_name']?.toString() ?? '',
            location: LatLng(
              _asDouble(place['lat']),
              _asDouble(place['lon']),
            ),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching address: $e');
      return [];
    }
  }

  /// Get route polyline and road distance using OSRM API.
  Future<MapRoute> getRoute(LatLng start, LatLng end) async {
    try {
      final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
      final response = await _dio.get<Map<String, dynamic>>(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final routes = data?['routes'];
        if (routes is List<dynamic> && routes.isNotEmpty) {
          final route = Map<String, dynamic>.from(routes.first as Map);
          final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
          final coordinates = geometry['coordinates'];
          if (coordinates is! List<dynamic>) {
            return MapRoute(
              points: const [],
              distanceKm: straightLineDistanceKm(start, end),
            );
          }

          final points = coordinates.map((coord) {
            final pair = coord as List<dynamic>;
            return LatLng(_asDouble(pair[1]), _asDouble(pair[0]));
          }).toList();
          final meters = route['distance'];
          final distanceKm = meters is num
              ? meters.toDouble() / 1000
              : _polylineDistanceKm(points);

          return MapRoute(points: points, distanceKm: distanceKm);
        }
      }
      return MapRoute(
        points: const [],
        distanceKm: straightLineDistanceKm(start, end),
      );
    } catch (e) {
      print('Error getting route: $e');
      return MapRoute(
        points: const [],
        distanceKm: straightLineDistanceKm(start, end),
      );
    }
  }

  double straightLineDistanceKm(LatLng start, LatLng end) {
    return _distance.as(LengthUnit.Kilometer, start, end);
  }

  static double _polylineDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0;

    var totalMeters = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      totalMeters += _distance(points[i], points[i + 1]);
    }
    return totalMeters / 1000;
  }

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
