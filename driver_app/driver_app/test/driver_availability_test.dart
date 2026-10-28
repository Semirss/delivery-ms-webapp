import 'dart:async';

import 'package:driver_app/core/operations/driver_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'an explicit Offline choice wins over an in-flight Online sync',
    () async {
      const driverId = 'availability-race-test';
      final onlineResponse = Completer<String>();
      final writes = <String>[];

      DriverAvailability.choose(driverId, true);
      final online = DriverAvailability.writeIfChosen(driverId, true, () {
        writes.add('online');
        return onlineResponse.future;
      });
      await Future<void>.delayed(Duration.zero);

      DriverAvailability.choose(driverId, false);
      final offline = DriverAvailability.writeIfChosen(
        driverId,
        false,
        () async {
          writes.add('offline');
          return 'offline';
        },
      );
      onlineResponse.complete('online');

      expect(await online, isNull);
      expect(await offline, 'offline');
      expect(writes, ['online', 'offline']);
      expect(DriverAvailability.choiceFor(driverId), false);
    },
  );

  test('a queued automatic Online write is skipped after Offline', () async {
    const driverId = 'availability-queued-test';
    final release = Completer<String>();
    var staleOnlineWrites = 0;

    DriverAvailability.choose(driverId, true);
    final first = DriverAvailability.writeIfChosen(
      driverId,
      true,
      () => release.future,
    );
    final stale = DriverAvailability.writeIfChosen(driverId, true, () async {
      staleOnlineWrites++;
      return 'stale';
    });
    DriverAvailability.choose(driverId, false);
    final offline = DriverAvailability.writeIfChosen(
      driverId,
      false,
      () async => 'offline',
    );
    release.complete('online');

    expect(await first, isNull);
    expect(await stale, isNull);
    expect(await offline, 'offline');
    expect(staleOnlineWrites, 0);
  });
}
