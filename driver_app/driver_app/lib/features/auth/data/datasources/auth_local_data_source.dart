import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:driver_app/core/databases/cache/cache_helper.dart';
import 'package:driver_app/core/errors/failure.dart';
import 'package:driver_app/core/storage/storage_adapter.dart';
import 'package:driver_app/core/storage/storage_key_constants.dart';
import 'package:injectable/injectable.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<void> cacheAccessToken(String token);
  Future<void> cacheRefreshToken(String token);
  Future<void> cacheVerificationKey(String key);
  Future<void> cacheLoginTimestamp(int timestamp);
  Future<UserModel?> getCachedUser();
  Future<String?> getCachedAccessToken();
  Future<String?> getCachedRefreshToken();
  Future<String?> getCachedVerificationKey();
  Future<void> clearAll();
}

@Injectable(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final CacheHelper cacheHelper;

  AuthLocalDataSourceImpl({required this.cacheHelper});

  Future<void> _cacheInStorageService(StorageKeys key, dynamic value) async {
    try {
      final storageService = GetIt.instance<IStorageService>();
      await storageService.saveData(key, value);
    } catch (_) {
      // Best-effort to keep StorageService in sync with CacheHelper.
    }
  }

  Future<void> _clearFromStorageService(StorageKeys key) async {
    try {
      final storageService = GetIt.instance<IStorageService>();
      await storageService.clearData(key);
    } catch (_) {
      // Best-effort to keep StorageService in sync with CacheHelper.
    }
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await cacheHelper.saveData(
        key: StorageKeys.user.name,
        value: json.encode(user.toJson()),
      );
      await _cacheInStorageService(
        StorageKeys.user,
        json.encode(user.toJson()),
      );
    } catch (e) {
      throw CacheFailure('Failed to cache user: $e');
    }
  }

  @override
  Future<void> cacheAccessToken(String token) async {
    try {
      await cacheHelper.saveData(
        key: StorageKeys.accessToken.name,
        value: token,
      );
      await _cacheInStorageService(StorageKeys.accessToken, token);
    } catch (e) {
      throw CacheFailure('Failed to cache access token: $e');
    }
  }

  @override
  Future<void> cacheRefreshToken(String token) async {
    try {
      await cacheHelper.saveData(
        key: StorageKeys.refreshToken.name,
        value: token,
      );
      await _cacheInStorageService(StorageKeys.refreshToken, token);
    } catch (e) {
      throw CacheFailure('Failed to cache refresh token: $e');
    }
  }

  @override
  Future<void> cacheVerificationKey(String key) async {
    try {
      await cacheHelper.saveData(
        key: StorageKeys.verificationKey.name,
        value: key,
      );
      await _cacheInStorageService(StorageKeys.verificationKey, key);
    } catch (e) {
      throw CacheFailure('Failed to cache verification key: $e');
    }
  }

  @override
  Future<void> cacheLoginTimestamp(int timestamp) async {
    try {
      await cacheHelper.saveData(
        key: StorageKeys.loginTimestamp.name,
        value: timestamp,
      );
      await _cacheInStorageService(StorageKeys.loginTimestamp, timestamp);
    } catch (e) {
      throw CacheFailure('Failed to cache login timestamp: $e');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final userJson = cacheHelper.getDataString(key: StorageKeys.user.name);
      if (userJson != null) {
        final decoded = json.decode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(decoded);
      }
      return null;
    } catch (e) {
      throw CacheFailure('Failed to get cached user: $e');
    }
  }

  @override
  Future<String?> getCachedAccessToken() async {
    try {
      return cacheHelper.getDataString(key: StorageKeys.accessToken.name);
    } catch (e) {
      throw CacheFailure('Failed to get cached access token: $e');
    }
  }

  @override
  Future<String?> getCachedRefreshToken() async {
    try {
      return cacheHelper.getDataString(key: StorageKeys.refreshToken.name);
    } catch (e) {
      throw CacheFailure('Failed to get cached refresh token: $e');
    }
  }

  @override
  Future<String?> getCachedVerificationKey() async {
    try {
      return cacheHelper.getDataString(key: StorageKeys.verificationKey.name);
    } catch (e) {
      throw CacheFailure('Failed to get cached verification key: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await cacheHelper.removeData(key: StorageKeys.user.name);
      await cacheHelper.removeData(key: StorageKeys.accessToken.name);
      await cacheHelper.removeData(key: StorageKeys.refreshToken.name);
      await cacheHelper.removeData(key: StorageKeys.verificationKey.name);
      await cacheHelper.removeData(key: StorageKeys.loginTimestamp.name);
      await _clearFromStorageService(StorageKeys.user);
      await _clearFromStorageService(StorageKeys.accessToken);
      await _clearFromStorageService(StorageKeys.refreshToken);
      await _clearFromStorageService(StorageKeys.verificationKey);
      await _clearFromStorageService(StorageKeys.loginTimestamp);
    } catch (e) {
      throw CacheFailure('Failed to clear auth data: $e');
    }
  }
}
