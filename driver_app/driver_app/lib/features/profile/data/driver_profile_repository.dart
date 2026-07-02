import 'package:driver_app/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverProfileRepository {
  DriverProfileRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<DriverProfileSnapshot> load(UserEntity? user) async {
    final driver = await resolveDriver(user);
    if (driver == null) {
      return const DriverProfileSnapshot.empty(
        errorMessage: 'Driver profile was not found for this account.',
      );
    }

    final driverId = driver['id']?.toString();
    if (driverId == null || driverId.isEmpty) {
      return DriverProfileSnapshot(
        driver: driver,
        deliveries: const [],
        rating: const DriverRatingSummary.empty(),
        unreadNotifications: 0,
        errorMessage: 'Driver profile is missing its identifier.',
      );
    }

    final deliveries = await _loadDeliveries(driverId);
    final rating = await _loadRatingSummary(driverId);
    final unreadNotifications = await _loadUnreadNotificationCount(driver);

    return DriverProfileSnapshot(
      driver: driver,
      deliveries: deliveries,
      rating: rating,
      unreadNotifications: unreadNotifications,
    );
  }

  Future<Map<String, dynamic>?> resolveDriver(UserEntity? user) async {
    if (user != null) {
      final byId = await _maybeDriverBy('id', user.id);
      if (byId != null) return byId;

      final phone = _clean(user.phone);
      if (phone != null) {
        final byPhone = await _maybeDriverBy('phone', phone);
        if (byPhone != null) return byPhone;
      }

      final emailAsPhone = _clean(user.email);
      if (emailAsPhone != null) {
        final byEmailPhone = await _maybeDriverBy('phone', emailAsPhone);
        if (byEmailPhone != null) return byEmailPhone;
      }

      final name = _driverName(user);
      if (name != null) {
        final byName = await _maybeDriverBy('name', name);
        if (byName != null) return byName;
      }
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    final bySupabaseId = await _maybeDriverBy('id', currentUser.id);
    if (bySupabaseId != null) return bySupabaseId;

    final metadataPhone = currentUser.userMetadata?['phone']?.toString();
    for (final candidate in [
      currentUser.phone,
      metadataPhone,
      currentUser.email,
    ]) {
      final value = _clean(candidate);
      if (value == null) continue;
      final byPhone = await _maybeDriverBy('phone', value);
      if (byPhone != null) return byPhone;
    }

    return null;
  }

  Future<void> updateDriver(
    String driverId,
    Map<String, dynamic> values,
  ) async {
    await _supabase.from('drivers').update(values).eq('id', driverId);
  }

  Future<Map<String, dynamic>?> _maybeDriverBy(
    String column,
    String value,
  ) async {
    if (value.trim().isEmpty) return null;
    try {
      final data = await _supabase
          .from('drivers')
          .select()
          .eq(column, value)
          .maybeSingle();
      if (data == null) return null;
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _loadDeliveries(String driverId) async {
    try {
      final data = await _supabase
          .from('deliveries')
          .select()
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(150);

      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return const [];
    }
  }

  Future<DriverRatingSummary> _loadRatingSummary(String driverId) async {
    try {
      final data = await _supabase
          .from('delivery_ratings')
          .select('rating')
          .eq('ratee_type', 'driver')
          .eq('ratee_id', driverId);

      final ratings = List<Map<String, dynamic>>.from(data)
          .map((row) => asInt(row['rating']))
          .where((rating) => rating > 0)
          .toList();
      if (ratings.isEmpty) return const DriverRatingSummary.empty();

      final total = ratings.fold<int>(0, (sum, rating) => sum + rating);
      return DriverRatingSummary(
        average: total / ratings.length,
        count: ratings.length,
      );
    } catch (_) {
      return const DriverRatingSummary.empty();
    }
  }

  Future<int> _loadUnreadNotificationCount(Map<String, dynamic> driver) async {
    try {
      final data = await _supabase
          .from('app_notifications')
          .select('id, recipient_id, recipient_phone, read_at')
          .eq('app', 'driver')
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(data)
          .where((notification) => matchesDriverNotification(notification, driver))
          .where((notification) => notification['read_at'] == null)
          .length;
    } catch (_) {
      return 0;
    }
  }

  String? _driverName(UserEntity user) {
    final name = [
      user.firstName,
      user.lastName,
    ].where((part) => _clean(part) != null).join(' ').trim();
    return _clean(name);
  }
}

class DriverProfileSnapshot {
  const DriverProfileSnapshot({
    required this.driver,
    required this.deliveries,
    required this.rating,
    required this.unreadNotifications,
    this.errorMessage,
  });

  const DriverProfileSnapshot.empty({this.errorMessage})
    : driver = null,
      deliveries = const [],
      rating = const DriverRatingSummary.empty(),
      unreadNotifications = 0;

  final Map<String, dynamic>? driver;
  final List<Map<String, dynamic>> deliveries;
  final DriverRatingSummary rating;
  final int unreadNotifications;
  final String? errorMessage;

  bool get hasDriver => driver != null;

  String? get driverId => driver?['id']?.toString();

  String get name => valueText(driver?['name'], fallback: 'Driver');

  String get phone => valueText(driver?['phone'], fallback: 'No phone added');

  String get status => valueText(driver?['status'], fallback: 'Offline');

  String get approvalStatus =>
      valueText(driver?['approval_status'], fallback: 'Pending');

  String get vehicleType =>
      valueText(driver?['vehicle_type'], fallback: 'Motorbike');

  String get plateNumber =>
      valueText(driver?['plate_number'], fallback: 'Not added');

  String get telegramUsername =>
      valueText(driver?['telegram_username'], fallback: 'Not connected');

  String? get personalIdUrl => _clean(driver?['personal_id_url']?.toString());

  DateTime? get createdAt => asDate(driver?['created_at']);

  DateTime? get lastLocationUpdate =>
      asDate(driver?['last_location_update']);

  int get completedDeliveries =>
      deliveries.where((delivery) => delivery['status'] == 'Delivered').length;

  int get activeDeliveries => deliveries
      .where((delivery) => ['Assigned', 'Picked Up'].contains(delivery['status']))
      .length;

  int get cancelledDeliveries =>
      deliveries.where((delivery) => delivery['status'] == 'Cancelled').length;

  int get reportedDeliveries => asInt(driver?['total_deliveries']);

  int get displayDeliveries =>
      completedDeliveries > reportedDeliveries ? completedDeliveries : reportedDeliveries;

  double get totalEarnings => deliveries
      .where((delivery) => delivery['status'] == 'Delivered')
      .fold<double>(
        0,
        (sum, delivery) => sum + asMoney(delivery['delivery_fee']),
      );

  double get averageDeliveryFee {
    if (completedDeliveries == 0) return 0;
    return totalEarnings / completedDeliveries;
  }

  double get todayEarnings {
    final now = DateTime.now();
    return deliveries.where((delivery) {
      final createdAt = asDate(delivery['created_at']);
      return delivery['status'] == 'Delivered' &&
          createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).fold<double>(
      0,
      (sum, delivery) => sum + asMoney(delivery['delivery_fee']),
    );
  }

  int get todayDeliveries {
    final now = DateTime.now();
    return deliveries.where((delivery) {
      final createdAt = asDate(delivery['created_at']);
      return delivery['status'] == 'Delivered' &&
          createdAt != null &&
          createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).length;
  }

  double get weekEarnings {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return deliveries.where((delivery) {
      final createdAt = asDate(delivery['created_at']);
      return delivery['status'] == 'Delivered' &&
          createdAt != null &&
          createdAt.isAfter(cutoff);
    }).fold<double>(
      0,
      (sum, delivery) => sum + asMoney(delivery['delivery_fee']),
    );
  }

  DateTime? get lastDeliveryAt {
    for (final delivery in deliveries) {
      final date = asDate(delivery['created_at']);
      if (date != null) return date;
    }
    return null;
  }
}

class DriverRatingSummary {
  const DriverRatingSummary({
    required this.average,
    required this.count,
  });

  const DriverRatingSummary.empty()
    : average = 0,
      count = 0;

  final double average;
  final int count;

  bool get hasRatings => count > 0;

  String get label => hasRatings ? average.toStringAsFixed(1) : 'New';
}

bool matchesDriverNotification(
  Map<String, dynamic> notification,
  Map<String, dynamic> driver,
) {
  final recipientId = _clean(notification['recipient_id']?.toString());
  final recipientPhone = _clean(notification['recipient_phone']?.toString());
  final driverId = _clean(driver['id']?.toString());
  final driverPhone = _clean(driver['phone']?.toString());

  if (recipientId == null && recipientPhone == null) return true;
  if (driverId != null && recipientId == driverId) return true;
  if (driverPhone != null && recipientPhone == driverPhone) return true;
  return false;
}

String valueText(Object? value, {String fallback = '--'}) {
  final text = _clean(value?.toString());
  return text ?? fallback;
}

String moneyText(Object? value) {
  final amount = asMoney(value);
  return '${amount.toStringAsFixed(0)} ETB';
}

double asMoney(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? asDate(Object? value) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
