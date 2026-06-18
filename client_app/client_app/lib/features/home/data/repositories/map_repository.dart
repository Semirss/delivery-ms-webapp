import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class MapPlace {
  final String displayName;
  final LatLng location;

  MapPlace({required this.displayName, required this.location});
}

class MapRepository {
  final Dio _dio = Dio();

  /// Search address using OpenStreetMap Nominatim API
  Future<List<MapPlace>> searchAddress(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
        },
        options: Options(
          headers: {
            'User-Agent': 'MotorideClient/1.0', // Required by Nominatim policy
          },
        ),
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((item) {
          return MapPlace(
            displayName: item['display_name'] as String,
            location: LatLng(
              double.parse(item['lat']),
              double.parse(item['lon']),
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
