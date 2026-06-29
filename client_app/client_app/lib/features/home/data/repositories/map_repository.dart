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
  static const List<_AddisPlace> _priorityAddisPlaces = [
    _AddisPlace('Bole', 8.9947, 38.7891, [
      'bole',
      'bole medhanialem',
      'bole road',
      'edna mall',
    ]),
    _AddisPlace('Bole Atlas', 8.9979, 38.7815, [
      'atlas',
      'bole atlas',
      'atlas hotel',
    ]),
    _AddisPlace('CMC', 9.0272, 38.8429, [
      'cmc',
      'cmc michael',
      'cmc square',
    ]),
    _AddisPlace('Gurd Shola', 9.0223, 38.8140, [
      'gurd shola',
      'gurdi shola',
      'shola',
    ]),
    _AddisPlace('Piassa', 9.0369, 38.7524, [
      'piazza',
      'piassa',
      'arada',
    ]),
    _AddisPlace('Kazanchis', 9.0133, 38.7652, [
      'kazanchis',
      'kasanchis',
      'kazanchis area',
    ]),
    _AddisPlace('Meskel Square', 9.0104, 38.7612, [
      'meskel',
      'meskel square',
      'stadium',
    ]),
    _AddisPlace('Gotera', 8.9964, 38.7665, [
      'gotera',
      'gotera interchange',
      'gotera condominium',
    ]),
    _AddisPlace('Summit', 9.0311, 38.8688, [
      'summi',
      'summit square',
      'summit condominium',
      'summit mazoria',
    ]),
    _AddisPlace('Lideta square', 9.0155, 38.7344, [
      'ledeta',
      'lideta',
      'ledeta square',
    ]),
    _AddisPlace('Hayat', 9.0250, 38.8500, [
      'hayat hospital',
      'yeka hayat',
      'ayat hayat',
    ]),
    _AddisPlace('Torhailoch Square', 9.0125, 38.7233, [
      'torh',
      'tor hayloch',
      'tor hailoch',
      'torhayloch',
      'torhailoch',
    ]),
    _AddisPlace('Kality Menaharia', 8.8955, 38.7583, [
      'kaliti',
      'kality',
      'kality bus station',
      'kality square',
    ]),
    _AddisPlace('Saris Abo', 8.9711, 38.7633, [
      'saris',
      'saris adey abeba',
      'saris abo',
    ]),
    _AddisPlace('Jemo', 8.9588, 38.7246, [
      'jemo',
      'jemo michael',
      'jemo condominium',
    ]),
    _AddisPlace('Lebu', 8.9645, 38.7184, [
      'lebu',
      'lebu mebrat',
      'lebu medhanialem',
    ]),
    _AddisPlace('Old Airport', 8.9960, 38.7291, [
      'old airport',
      'airport area',
      'bisrate gabriel',
    ]),
    _AddisPlace('Zenebe Werk', 9.0300, 38.7055, [
      'zenba wer',
      'zenbe werk',
      'zenebe work',
      'zenebe werk',
    ]),
    _AddisPlace('Haya Hulet 22', 9.0069, 38.7852, [
      '22',
      'haya hulet',
      'haya hulet 22',
      '22 mazoria',
    ]),
    _AddisPlace('Megenagna', 9.0194, 38.8005, [
      'megenag',
      'megenagna taxi station',
      'megenagna shola',
    ]),
    _AddisPlace('Merkato', 9.0277, 38.7388, [
      'mercato',
      'merkato',
      'merkato terminal',
      'autobus tera',
    ]),
    _AddisPlace('Mexico Square', 9.0097, 38.7458, [
      'mex',
      'mexico',
      'mexico square',
    ]),
    _AddisPlace('Weyra Sefer', 8.9955, 38.7555, [
      'weyra',
      'weyra sefer',
      'weira sefer',
    ]),
    _AddisPlace('Ayat', 9.0266, 38.8580, ['ayat', 'ayat real estate']),
  ];

  static List<MapPlace> get majorAddisPlaces => _priorityAddisPlaces
      .map(_placeToMapPlace)
      .toList(growable: false);

  /// Search address using OpenStreetMap Nominatim API
  Future<List<MapPlace>> searchAddress(String query) async {
    final localMatches = _localAddisMatches(query);
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Addis Ababa, Ethiopia',
          'format': 'json',
          'addressdetails': 1,
          'countrycodes': 'et',
          'bounded': 1,
          'viewbox': '38.62,9.12,38.92,8.82',
          'limit': 8,
        },
        options: Options(
          headers: {
            'User-Agent': 'MotoBikeClient/1.0', // Required by Nominatim policy
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data ?? <dynamic>[];
        final onlineMatches = data.map((item) {
          final place = Map<String, dynamic>.from(item as Map);
          return MapPlace(
            displayName: place['display_name']?.toString() ?? '',
            location: LatLng(_asDouble(place['lat']), _asDouble(place['lon'])),
          );
        }).toList();
        return _dedupePlaces([...localMatches, ...onlineMatches]);
      }
      return localMatches;
    } catch (e) {
      print('Error searching address: $e');
      return localMatches;
    }
  }

  /// Get route polyline and road distance using OSRM API.
  Future<MapRoute> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
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

  static List<MapPlace> _localAddisMatches(String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return [];

    final matches =
        _priorityAddisPlaces.where((place) {
          return place.searchTerms.any((term) {
            final normalizedTerm = _normalize(term);
            return normalizedTerm.contains(normalizedQuery) ||
                normalizedQuery.contains(normalizedTerm);
          });
        }).toList()..sort((a, b) {
          final aStarts = _normalize(a.name).startsWith(normalizedQuery)
              ? 0
              : 1;
          final bStarts = _normalize(b.name).startsWith(normalizedQuery)
              ? 0
              : 1;
          return aStarts.compareTo(bStarts);
        });

    return matches
        .map(_placeToMapPlace)
        .toList();
  }

  static MapPlace _placeToMapPlace(_AddisPlace place) {
    return MapPlace(
      displayName: '${place.name}, Addis Ababa, Ethiopia',
      location: LatLng(place.lat, place.lng),
    );
  }

  static List<MapPlace> _dedupePlaces(List<MapPlace> places) {
    final seen = <String>{};
    final deduped = <MapPlace>[];
    for (final place in places) {
      final key =
          '${place.location.latitude.toStringAsFixed(5)},${place.location.longitude.toStringAsFixed(5)}';
      if (seen.add(key)) deduped.add(place);
    }
    return deduped;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}

class _AddisPlace {
  const _AddisPlace(this.name, this.lat, this.lng, this.aliases);

  final String name;
  final double lat;
  final double lng;
  final List<String> aliases;

  Iterable<String> get searchTerms => [name, ...aliases];
}
