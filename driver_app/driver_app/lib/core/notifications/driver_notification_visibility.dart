import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverNotificationVisibility {
  static const clearedIdsKey = 'driver_cleared_notification_ids';

  static bool isRelevant(Map<String, dynamic> notification) {
    if (notification['type'] != 'delivery_status') return true;
    final title = notification['title']?.toString().toLowerCase() ?? '';
    return title.contains('delivered') || title.contains('completed');
  }

  // The home tab stays mounted while the alerts tab is open.
  static final ValueNotifier<Set<String>> hiddenFromBadge =
      ValueNotifier<Set<String>>(<String>{});
  static Future<void> _clearQueue = Future<void>.value();

  static Future<Set<String>> loadClearedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return Set<String>.from(
      prefs.getStringList(clearedIdsKey) ?? const <String>[],
    );
  }

  static Future<Set<String>> clearIds(Iterable<String> ids) {
    final idsToClear = ids.toSet();
    final operation = _clearQueue.then((_) async {
      final nextIds = {...await loadClearedIds(), ...idsToClear};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(clearedIdsKey, nextIds.toList());
      hideFromBadge(idsToClear);
      return nextIds;
    });
    _clearQueue = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  static void hideFromBadge(Iterable<String> ids) {
    hiddenFromBadge.value = {...hiddenFromBadge.value, ...ids};
  }

  static int unreadCount(
    Iterable<Map<String, dynamic>> notifications, {
    required Set<String> clearedIds,
    required Set<String> hiddenIds,
  }) => notifications.where((notification) {
    final id = notification['id']?.toString();
    return isRelevant(notification) && notification['read_at'] == null &&
        (id == null || (!clearedIds.contains(id) && !hiddenIds.contains(id)));
  }).length;
}
