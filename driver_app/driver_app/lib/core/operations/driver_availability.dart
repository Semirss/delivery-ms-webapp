import 'dart:async';

import 'package:flutter/foundation.dart';

/// The driver's availability choice is separate from GPS and row refreshes.
class DriverAvailability {
  DriverAvailability._();

  static final ValueNotifier<(String, bool)?> changes = ValueNotifier(null);
  static final Map<String, bool> _choices = {};
  static final Map<String, Future<void>> _pending = {};

  static bool? choiceFor(String driverId) => _choices[driverId];

  static void choose(String driverId, bool online) {
    _choices[driverId] = online;
    changes.value = (driverId, online);
  }

  /// Serialize availability writes from Home and Settings. A queued automatic
  /// Online write is skipped when the driver has chosen Offline meanwhile.
  static Future<T?> writeIfChosen<T>(
    String driverId,
    bool online,
    Future<T> Function() write,
  ) async {
    final previous = _pending[driverId] ?? Future<void>.value();
    final finished = Completer<void>();
    _pending[driverId] = finished.future;
    await previous;
    try {
      if (_choices[driverId] != online) return null;
      final result = await write();
      return _choices[driverId] == online ? result : null;
    } finally {
      finished.complete();
      if (identical(_pending[driverId], finished.future)) {
        _pending.remove(driverId);
      }
    }
  }
}
