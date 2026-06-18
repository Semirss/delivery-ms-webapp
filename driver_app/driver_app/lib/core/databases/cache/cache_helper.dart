import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  //! Here The Initialize of cache .
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  //! this method to put data in local database using key

  String? getDataString({required String key}) {
    return sharedPreferences.getString(key);
  }

  //! this method to put data in local database using key

  Future<bool> saveData({required String key, required dynamic value}) async {
    if (value is bool) {
      return sharedPreferences.setBool(key, value);
    }
    if (value is String) {
      return sharedPreferences.setString(key, value);
    }

    if (value is int) {
      return sharedPreferences.setInt(key, value);
    } else if (value is double) {
      return sharedPreferences.setDouble(key, value);
    } else {
      // Default to double if not recognized
      return sharedPreferences.setDouble(key, (value as num).toDouble());
    }
  }

  //! this method to get data already saved in local database

  dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  //! remove data using specific key

  Future<bool> removeData({required String key}) async {
    return sharedPreferences.remove(key);
  }

  //! this method to check if local database contains {key}
  Future<bool> containsKey({required String key}) async {
    return sharedPreferences.containsKey(key);
  }

  //! clear all data in the local database
  Future<bool> clearData() async {
    return sharedPreferences.clear();
  }

  //! this method to put data in local database using key
  Future<dynamic> put({required String key, required dynamic value}) async {
    if (value is String) {
      return sharedPreferences.setString(key, value);
    } else if (value is bool) {
      return sharedPreferences.setBool(key, value);
    } else if (value is int) {
      return sharedPreferences.setInt(key, value);
    } else {
      return sharedPreferences.setDouble(key, (value as num).toDouble());
    }
  }
}
