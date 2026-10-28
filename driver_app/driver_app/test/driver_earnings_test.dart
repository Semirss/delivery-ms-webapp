import 'package:driver_app/features/profile/data/driver_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'net earnings use the agreed share while old trips preserve their fee',
    () {
      expect(
        netDeliveryEarnings({'delivery_fee': 200, 'driver_earnings': 176}),
        176,
      );
      expect(
        netDeliveryEarnings({'delivery_fee': 200, 'driver_earnings': 0}),
        0,
      );
      expect(netDeliveryEarnings({'delivery_fee': 200}), 200);
    },
  );
  test('today counts the completion date of a trip requested yesterday', () {
    final now = DateTime.now();
    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(hours: 1));
    final snapshot = DriverProfileSnapshot(
      driver: const {'id': 'driver'},
      deliveries: [
        {
          'status': 'Delivered',
          'created_at': yesterday.toIso8601String(),
          'completed_at': now.toIso8601String(),
          'delivery_fee': 200,
          'driver_earnings': 176,
        },
      ],
      rating: const DriverRatingSummary.empty(),
      unreadNotifications: 0,
    );
    expect(snapshot.todayDeliveries, 1);
    expect(snapshot.todayEarnings, 176);
    expect(snapshot.totalEarnings, 176);
  });
}
