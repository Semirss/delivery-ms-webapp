import 'package:dio/dio.dart';
import 'package:driver_app/core/config/app_config.dart';
import 'package:driver_app/core/storage/storage_key_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverOperationsApi {
  DriverOperationsApi({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  Future<Map<String, dynamic>> request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    final base = AppConfig().apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty)
      throw Exception('Driver service is not configured. Contact dispatch.');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.accessToken.name);
    if (token == null || token.split('.').length != 3) {
      throw Exception(
        'Please sign out and sign in again to activate your secure driver session.',
      );
    }
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        '$base$path',
        data: data,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (error) {
      final body = error.response?.data;
      throw Exception(
        body is Map
            ? body['error'] ?? 'Driver service request failed.'
            : 'Connection failed. Check your connection and try again.',
      );
    }
  }

  Future<Map<String, dynamic>> load() => request('/api/driver/operations');
  Future<Map<String, dynamic>> update(Map<String, dynamic> data) =>
      request('/api/driver/operations', method: 'PATCH', data: data);
  Future<Map<String, dynamic>> deliveryAction(String id, String action) =>
      request(
        '/api/driver/deliveries/${Uri.encodeComponent(id)}',
        method: 'POST',
        data: {'action': action},
      );
  Future<Map<String, dynamic>> walletRequest(Map<String, dynamic> data) =>
      request('/api/driver/wallet', method: 'POST', data: data);
}
