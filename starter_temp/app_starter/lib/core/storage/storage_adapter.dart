import 'package:app_starter/core/logging/app_logger.dart';

import 'storage_key_constants.dart';

abstract class IStorageService {
  Future<void> initialize([AppLogger? logger]);
  Future<void> saveData(StorageKeys key, dynamic value);
  dynamic getData(StorageKeys key);
  bool hasData(StorageKeys key);
  Future<void> clearData(StorageKeys key);
}

abstract class IStorageAdapter {
  Future<void> saveData(String key, dynamic value);
  dynamic getData(String key);
  bool hasData(String key);
  Future<void> deleteData(String key);
  Future<void> clearAllData();
}

class SharedPreferencesAdapter implements IStorageAdapter {
  @override
  Future<void> saveData(String key, value) async {
    // Implementation would use SharedPreferences
    throw UnimplementedError();
  }

  @override
  dynamic getData(String key) {
    // Implementation would use SharedPreferences
    throw UnimplementedError();
  }

  @override
  bool hasData(String key) {
    // Implementation would use SharedPreferences
    throw UnimplementedError();
  }

  @override
  Future<void> deleteData(String key) async {
    // Implementation would use SharedPreferences
    throw UnimplementedError();
  }

  @override
  Future<void> clearAllData() async {
    // Implementation would use SharedPreferences
    throw UnimplementedError();
  }
}
