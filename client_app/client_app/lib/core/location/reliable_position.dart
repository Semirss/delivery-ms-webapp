import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

const _lastKnownMaxAge = Duration(minutes: 3);
const _webPositionTimeout = Duration(seconds: 6);
const _excellentWebAccuracyMeters = 50.0;
const _usableWebAccuracyMeters = 150.0;

Future<Position> readReliableCurrentPosition() async {
  final lastKnown = await _freshLastKnownPosition();
  if (lastKnown != null) return lastKnown;

  if (!kIsWeb) {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 6),
    );
  }

  return _readBestWebPosition();
}

Future<Position?> _freshLastKnownPosition() async {
  try {
    final position = await Geolocator.getLastKnownPosition();
    if (position == null) return null;

    final age = DateTime.now().difference(position.timestamp.toLocal());
    if (age <= _lastKnownMaxAge) return position;
  } catch (_) {
    return null;
  }
  return null;
}

Future<Position> _readBestWebPosition() async {
  final completer = Completer<Position>();
  StreamSubscription<Position>? subscription;
  Timer? settleTimer;
  Position? bestPosition;

  double accuracyOf(Position position) {
    final accuracy = position.accuracy;
    return accuracy.isFinite && accuracy > 0 ? accuracy : double.infinity;
  }

  void finishWithPosition() {
    if (completer.isCompleted || bestPosition == null) return;
    completer.complete(bestPosition);
  }

  void consider(Position position) {
    final currentBest = bestPosition;
    if (currentBest == null || accuracyOf(position) < accuracyOf(currentBest)) {
      bestPosition = position;
    }

    settleTimer?.cancel();
    final accuracy = accuracyOf(bestPosition!);
    final settleDuration = accuracy <= _excellentWebAccuracyMeters
        ? const Duration(milliseconds: 250)
        : accuracy <= _usableWebAccuracyMeters
        ? const Duration(milliseconds: 800)
        : const Duration(milliseconds: 1500);
    settleTimer = Timer(settleDuration, finishWithPosition);
  }

  subscription =
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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
