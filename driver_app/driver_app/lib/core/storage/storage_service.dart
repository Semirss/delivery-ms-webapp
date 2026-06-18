// ignore_for_file: unawaited_futures

import 'package:flutter/foundation.dart';
import 'package:driver_app/core/logging/app_logger.dart';
import 'package:driver_app/core/storage/storage_adapter.dart';
import 'package:driver_app/core/storage/storage_key_constants.dart';
import 'package:driver_app/core/utils/functions/base_functions/data_functions.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

@Singleton(as: IStorageService)
class StorageService implements IStorageService {
  late Box<dynamic> _storage;
  AppLogger? _logger;

  @override
  Future<void> initialize([AppLogger? logger]) async {
    if (logger != null) {
      _logger = logger;
    }

    try {
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        Hive.init(directory.path);
      } else {
        Hive.initFlutter();
      }
      _storage = await Hive.openBox('storage');
      if (_logger != null) {
        _logger!.info('Storage initialized successfully');
      }
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error('Failed to initialize storage', e, stackTrace);
      }
      rethrow;
    }
  }

  @override
  Future<void> saveData(StorageKeys key, value) async {
    try {
      await _storage.put(key.name, value);
      outlog('Saved $value to $key');
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error(
          'Failed to save data for key: ${key.name}',
          e,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  @override
  dynamic getData(StorageKeys key) {
    try {
      final data = _storage.get(key.name);
      return data;
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error(
          'Failed to get data for key: ${key.name}',
          e,
          stackTrace,
        );
      }
      return null;
    }
  }

  @override
  Future<void> clearData(StorageKeys key) async {
    try {
      await _storage.delete(key.name);
      outlog('Deleted $key');
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error(
          'Failed to delete data for key: ${key.name}',
          e,
          stackTrace,
        );
      }
      rethrow;
    }
  }

  Future<void> clearAllData() async {
    try {
      await _storage.clear();
      outlog('Cleared storage');
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error('Failed to clear storage', e, stackTrace);
      }
      rethrow;
    }
  }

  @override
  bool hasData(StorageKeys key) {
    try {
      final data = _storage.containsKey(key.name);
      outlog('Checked if $key exists: $data');
      return data;
    } catch (e, stackTrace) {
      if (_logger != null) {
        _logger!.error(
          'Failed to check data for key: ${key.name}',
          e,
          stackTrace,
        );
      }
      return false;
    }
  }

  // Additional methods for token management
  Future<String?> getAccessToken() async {
    return getData(StorageKeys.accessToken) as String?;
  }

  Future<void> setAccessToken(String token) async {
    await saveData(StorageKeys.accessToken, token);
  }

  Future<String?> getRefreshToken() async {
    return getData(StorageKeys.refreshToken) as String?;
  }

  Future<void> setRefreshToken(String token) async {
    await saveData(StorageKeys.refreshToken, token);
  }

  Future<void> clearTokens() async {
    await clearData(StorageKeys.accessToken);
    await clearData(StorageKeys.refreshToken);
  }
}
