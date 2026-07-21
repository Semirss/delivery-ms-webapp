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
  MapRepository()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 4),
            sendTimeout: const Duration(seconds: 3),
          ),
        );

  final Dio _dio;
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
    _AddisPlace('Bole Medhanialem', 8.9974, 38.7866, [
      'bole medhanealem',
      'bole medhanialem',
      'medhanialem',
      'edna mall',
    ]),
    _AddisPlace('Bole Michael', 8.9829, 38.7888, [
      'bole michael',
      'bole mikhael',
      'bole mikael',
    ]),
    _AddisPlace('Bole Bulbula', 8.9256, 38.7856, [
      'bole bulbula',
      'bulbula',
      'bole bulibula',
    ]),
    _AddisPlace('Bole Arabsa', 8.9184, 38.8347, [
      'bole arabsa',
      'arabsa',
      'arabssa',
    ]),
    _AddisPlace('Gerji', 9.0104, 38.8068, [
      'gerji',
      'gerji mebrat hail',
      'gerji imperial',
    ]),
    _AddisPlace('Jacros', 9.0158, 38.8285, [
      'jacros',
      'jakros',
      'yekatit 12 square',
    ]),
    _AddisPlace('Figa', 9.0368, 38.8311, [
      'figa',
      'figa mebrat',
      'yeka figa',
    ]),
    _AddisPlace('Kotebe', 9.0336, 38.8175, [
      'kotebe',
      'kotebe college',
      'kotebe area',
    ]),
    _AddisPlace('Shola', 9.0262, 38.7956, [
      'shola',
      'shola market',
      'shola gebeya',
    ]),
    _AddisPlace('Urael', 9.0101, 38.7749, [
      'urael',
      'ural',
      'urael church',
    ]),
    _AddisPlace('Wollo Sefer', 8.9989, 38.7732, [
      'wello sefer',
      'wollo sefer',
      'bole wello sefer',
    ]),
    _AddisPlace('Olympia', 9.0058, 38.7637, [
      'olympia',
      'olympia square',
      'olympia area',
    ]),
    _AddisPlace('Lancha', 8.9964, 38.7466, [
      'lancha',
      'lancha area',
      'lancia',
    ]),
    _AddisPlace('Kera', 8.9864, 38.7477, [
      'kera',
      'kera area',
      'kera roundabout',
    ]),
    _AddisPlace('Sar Bet', 8.9913, 38.7328, [
      'sar bet',
      'sarbet',
      'sar bet area',
    ]),
    _AddisPlace('Mekanisa', 8.9771, 38.7288, [
      'mekanisa',
      'mekanissa',
      'mekanisa abo',
    ]),
    _AddisPlace('Lafto', 8.9585, 38.7404, [
      'lafto',
      'nifas silk lafto',
      'nifas silk',
    ]),
    _AddisPlace('Ayer Tena', 9.0046, 38.6925, [
      'ayer tena',
      'ayertena',
      'ayer tena square',
    ]),
    _AddisPlace('Alem Bank', 9.0151, 38.6898, [
      'alem bank',
      'alembank',
      'alem bank area',
    ]),
    _AddisPlace('Kolfe', 9.0302, 38.7072, [
      'kolfe',
      'kolfe keranio',
      'kolfe area',
    ]),
    _AddisPlace('Asko', 9.0711, 38.7054, [
      'asko',
      'asko addis sefer',
      'asko area',
    ]),
    _AddisPlace('Wingate', 9.0540, 38.7210, [
      'wingate',
      'winget',
      'wingate school',
    ]),
    _AddisPlace('Addisu Gebeya', 9.0467, 38.7330, [
      'addisu gebeya',
      'addis gebeya',
      'new market',
    ]),
    _AddisPlace('Shiro Meda', 9.0626, 38.7617, [
      'shiro meda',
      'shiromeda',
      'shiro meda market',
    ]),
    _AddisPlace('Entoto', 9.0836, 38.7648, [
      'entoto',
      'entoto maryam',
      'entoto park',
    ]),
    _AddisPlace('Arat Kilo', 9.0340, 38.7611, [
      '4 kilo',
      'arat kilo',
      'arat kilo square',
    ]),
    _AddisPlace('Sidist Kilo', 9.0445, 38.7612, [
      '6 kilo',
      'sidist kilo',
      'six kilo',
    ]),
    _AddisPlace('Amist Kilo', 9.0393, 38.7588, [
      '5 kilo',
      'amist kilo',
      'five kilo',
    ]),
    _AddisPlace('Kebena', 9.0352, 38.7778, [
      'kebena',
      'kebena area',
      'yeka kebena',
    ]),
    _AddisPlace('Ferensay Legasion', 9.0437, 38.7834, [
      'ferensay',
      'ferensay legasion',
      'french embassy',
    ]),
    _AddisPlace('Haya Arat 24', 9.0082, 38.7919, [
      '24',
      'haya arat',
      '24 mazoria',
    ]),
    _AddisPlace('Meri', 9.0153, 38.8641, [
      'meri',
      'meri luke',
      'meri area',
    ]),
    _AddisPlace('Yerer', 9.0234, 38.8878, [
      'yerer',
      'yerer ber',
      'yerer area',
    ]),
  ];

  static List<MapPlace> get majorAddisPlaces => _priorityAddisPlaces
      .map(_placeToMapPlace)
      .toList(growable: false);

  static List<MapPlace> localAddisMatches(String query) {
    return _localAddisMatches(query);
  }

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

  Future<MapPlace> describeLocation(
    LatLng location, {
    String fallbackName = 'Pinned location',
    bool exactPinLabel = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': location.latitude,
          'lon': location.longitude,
          'format': 'json',
          'addressdetails': 1,
          'zoom': 18,
        },
        options: Options(
          headers: {
            'User-Agent': 'MotoBikeClient/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final displayName = _reverseDisplayName(
          response.data ?? const <String, dynamic>{},
          location,
          fallbackName,
        );
        return MapPlace(
          displayName: exactPinLabel
              ? _exactPinnedDisplayName(location, fallbackName, displayName)
              : displayName,
          location: location,
        );
      }
    } catch (e) {
      print('Error describing location: $e');
    }

    final fallbackDisplayName = _nearestLocalDisplayName(
      location,
      fallbackName,
    );
    return MapPlace(
      displayName: exactPinLabel
          ? _exactPinnedDisplayName(location, fallbackName, fallbackDisplayName)
          : fallbackDisplayName,
      location: location,
    );
  }

  /// Get route polyline and road distance using OSRM API.
  Future<MapRoute> getRoute(LatLng start, LatLng end) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
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
      final lat = place.location.latitude.toStringAsFixed(5);
      final lng = place.location.longitude.toStringAsFixed(5);
      final key = '$lat,$lng';
      if (seen.add(key)) deduped.add(place);
    }
    return deduped;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
  }

  static String _reverseDisplayName(
    Map<String, dynamic> data,
    LatLng location,
    String fallbackName,
  ) {
    final addressSource = data['address'];
    final address = addressSource is Map
        ? Map<String, dynamic>.from(addressSource)
        : const <String, dynamic>{};

    final primary = _firstTextValue(address, const [
      'neighbourhood',
      'suburb',
      'quarter',
      'residential',
      'city_district',
      'road',
      'amenity',
    ]);
    final city = _firstTextValue(address, const [
      'city',
      'town',
      'state',
      'county',
    ]);
    final country = _firstTextValue(address, const ['country']) ?? 'Ethiopia';

    if (primary != null && primary != city) {
      return [
        primary,
        if (city != null && city != primary) city,
        country,
      ].join(', ');
    }

    final displayName = data['display_name']?.toString().trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.take(4).join(', ');
      }
    }

    return _nearestLocalDisplayName(location, fallbackName);
  }

  static String? _firstTextValue(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static String _nearestLocalDisplayName(LatLng location, String fallbackName) {
    _AddisPlace? nearest;
    var nearestMeters = double.infinity;

    for (final place in _priorityAddisPlaces) {
      final meters = _distance(
        location,
        LatLng(place.lat, place.lng),
      );
      if (meters < nearestMeters) {
        nearest = place;
        nearestMeters = meters;
      }
    }

    if (nearest != null && nearestMeters <= 3000) {
      return 'Near ${nearest.name}, Addis Ababa, Ethiopia';
    }

    return '$fallbackName, Addis Ababa, Ethiopia';
  }

  static String _exactPinnedDisplayName(
    LatLng location,
    String fallbackName,
    String nearbyName,
  ) {
    final label = fallbackName.trim().isEmpty
        ? 'Pinned location'
        : fallbackName.trim();
    final lat = location.latitude.toStringAsFixed(5);
    final lng = location.longitude.toStringAsFixed(5);
    final coordinates = '$lat, $lng';
    final nearby = _shortNearbyLabel(nearbyName, label);

    if (nearby == null) return '$label ($coordinates)';
    return '$label ($coordinates) - near $nearby';
  }

  static String? _shortNearbyLabel(String value, String fallbackName) {
    final normalizedFallback = fallbackName.toLowerCase();
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => part.toLowerCase() != 'ethiopia')
        .where((part) => part.toLowerCase() != 'addis ababa')
        .where((part) => part.toLowerCase() != normalizedFallback)
        .take(2)
        .toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
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
