import 'package:driver_app/core/notifications/driver_notification_visibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'cleared unread alerts disappear from the badge and stay cleared',
    () async {
      SharedPreferences.setMockInitialValues({});
      DriverNotificationVisibility.hiddenFromBadge.value = <String>{};
      final notifications = <Map<String, dynamic>>[
        {'id': 'first', 'read_at': null},
        {'id': 'second', 'read_at': null},
        {'id': 'read', 'read_at': '2026-01-01T00:00:00Z'},
      ];

      expect(
        DriverNotificationVisibility.unreadCount(
          notifications,
          clearedIds: <String>{},
          hiddenIds: DriverNotificationVisibility.hiddenFromBadge.value,
        ),
        2,
      );

      final cleared = await DriverNotificationVisibility.clearIds(['first']);
      expect(cleared, contains('first'));
      expect(
        DriverNotificationVisibility.hiddenFromBadge.value,
        contains('first'),
      );
      expect(
        await DriverNotificationVisibility.loadClearedIds(),
        contains('first'),
      );
      expect(
        DriverNotificationVisibility.unreadCount(
          notifications,
          clearedIds: cleared,
          hiddenIds: DriverNotificationVisibility.hiddenFromBadge.value,
        ),
        1,
      );

      DriverNotificationVisibility.hideFromBadge(['second']);
      expect(
        DriverNotificationVisibility.unreadCount(
          notifications,
          clearedIds: cleared,
          hiddenIds: DriverNotificationVisibility.hiddenFromBadge.value,
        ),
        0,
      );

      await Future.wait([
        DriverNotificationVisibility.clearIds(['second']),
        DriverNotificationVisibility.clearIds(['read']),
      ]);
      expect(
        await DriverNotificationVisibility.loadClearedIds(),
        containsAll(['first', 'second', 'read']),
      );
    },
  );
}
