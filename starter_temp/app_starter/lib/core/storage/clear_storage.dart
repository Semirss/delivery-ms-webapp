// ignore_for_file: unawaited_futures

import 'package:app_starter/core/storage/storage_adapter.dart';
import 'package:app_starter/core/storage/storage_key_constants.dart';
import 'package:app_starter/core/utils/functions/base_functions/data_functions.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ClearStorage {
  static Future<void> checkAndClearStorageOnUpgrade(
      IStorageService storageService) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final currentVersion = version;

    final storedVersion = storageService.getData(StorageKeys.version);
    outlog('Current version: $currentVersion $storedVersion');
    if (storedVersion != currentVersion) {
      outlog('Version changed from $storedVersion to $currentVersion');
      clearHiveCache(storageService);

      await clearCacheDirectory();

      // Save the new version
      await storageService.saveData(StorageKeys.version, currentVersion);
    }
  }

  static void clearHiveCache(IStorageService storageService) {
    final cacheKeys = [
      StorageKeys.user,
      StorageKeys.user,
      StorageKeys.user,
      StorageKeys.email,
      StorageKeys.phone,
      StorageKeys.password,
      StorageKeys.accessToken,
      // StorageKeys.refreshToken,
      StorageKeys.version,
    ];

    for (var key in cacheKeys) {
      storageService.clearData(key);
    }

    outlog('Hive cache cleared for version upgrade');
  }

  static Future<void> clearCacheDirectory() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        cacheDir.deleteSync(recursive: true);
        outlog('Cache directory cleared');
      }
    } catch (e) {
      outlog('Error clearing cache directory: $e');
    }
  }
}
