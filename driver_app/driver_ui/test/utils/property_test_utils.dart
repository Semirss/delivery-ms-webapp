import 'dart:math';

/// Utility class for property-based testing
class PropertyTestUtils {
  static final Random _random = Random();

  /// Runs a property test with the specified number of iterations
  static void runPropertyTest({
    required String description,
    required void Function() test,
    int iterations = 100,
  }) {
    for (int i = 0; i < iterations; i++) {
      try {
        test();
      } catch (e) {
        throw Exception(
          'Property test failed on iteration ${i + 1}/$iterations: $e',
        );
      }
    }
  }

  /// Runs an async property test with the specified number of iterations
  static Future<void> runAsyncPropertyTest({
    required String description,
    required Future<void> Function() test,
    int iterations = 100,
  }) async {
    for (int i = 0; i < iterations; i++) {
      try {
        await test();
      } catch (e) {
        throw Exception(
          'Property test failed on iteration ${i + 1}/$iterations: $e',
        );
      }
    }
  }

  /// Generates a random integer between min and max (inclusive)
  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }

  /// Generates a random boolean
  static bool randomBool() {
    return _random.nextBool();
  }

  /// Generates a random element from a list
  static T randomElement<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  /// Generates a random string of specified length
  static String randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }
}
