import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

const _webPositionTimeout = Duration(seconds: 10);
const _excellentWebAccuracyMeters = 50.0;
const _usableWebAccuracyMeters = 150.0;

Future<Position> readReliableCurrentPosition() {
  if (!kIsWeb) {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
  }

  return _readBestWebPosition();
}

Future<Position> _readBestWebPosition() async {
  final completer = Completer<Position>();
  StreamSubscription<Position>? subscription;
  Timer? settleTimer;
  Position? bestPosition;

  double accuracyOf(Position position) {
    final accuracy = position.accuracy;
    return accuracy.isFinite && accuracy > 0
        ? accuracy
        : double.infinity;
  }

  void finishWithPosition() {
    if (completer.isCompleted || bestPosition == null) return;
    completer.complete(bestPosition);
  }

  void consider(Position position) {
    final currentBest = bestPosition;
    if (currentBest == null ||
        accuracyOf(position) < accuracyOf(currentBest)) {
      bestPosition = position;
    }

    settleTimer?.cancel();
    final accuracy = accuracyOf(bestPosition!);
    final settleDuration = accuracy <= _excellentWebAccuracyMeters
        ? const Duration(milliseconds: 400)
        : accuracy <= _usableWebAccuracyMeters
        ? const Duration(milliseconds: 1500)
        : const Duration(seconds: 4);
    settleTimer = Timer(settleDuration, finishWithPosition);
  }

  subscription = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    ),
  ).listen(
    consider,
    onError: (Object error, StackTrace stackTrace) {
      if (completer.isCompleted) return;
      if (bestPosition != null) {
        completer.complete(bestPosition);
      } else {
        completer.completeError(error, stackTrace);
      }
    },
  );

  final hardTimeout = Timer(_webPositionTimeout, () {
    if (completer.isCompleted) return;
    if (bestPosition != null) {
      completer.complete(bestPosition);
    } else {
      completer.completeError(
        TimeoutException(
          'The browser did not return a GPS position in time.',
          _webPositionTimeout,
        ),
      );
    }
  });

  try {
    return await completer.future;
  } finally {
    hardTimeout.cancel();
    settleTimer?.cancel();
    await subscription.cancel();
  }
}
