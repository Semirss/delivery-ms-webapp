import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart' as dio;
import 'package:driver_app/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:driver_app/core/params/auth_params.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginParams params);
  Future<AuthResponseModel> signUp(SignUpParams params);
  Future<AuthResponseModel> verifyOtp(OtpVerificationParams params);
  Future<void> resendOtp(String verificationKey);
  Future<void> resetPassword(ResetPasswordParams params);
  Future<void> verifyResetPassword(VerifyResetPasswordParams params);
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

@Injectable(as: AuthRemoteDataSource)
class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  SupabaseAuthDataSourceImpl({AppConfig? config})
    : _config = config ?? AppConfig();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppConfig _config;

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty) throw Exception('Enter your driver email.');

    try {
      final apiLogin = await _tryLoginViaWebApi(
        LoginParams(email: email, password: params.password),
      );
      if (apiLogin != null) return apiLogin;
    } on dio.DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode >= 500 || statusCode == 0) rethrow;
    }

    final data = await _supabase
        .from('drivers')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (data == null) {
      throw Exception(
        'No driver account found with this email. Ask admin to add this email to your driver profile.',
      );
    }

    final driver = Map<String, dynamic>.from(data);
    if (driver['password']?.toString() != params.password) {
      throw Exception('Invalid email or password.');
    }

    final approvalStatus =
        driver['approval_status']?.toString().trim().isNotEmpty == true
        ? driver['approval_status'].toString()
        : 'Pending';

    if (approvalStatus == 'Pending') {
      throw Exception(
        'Waiting for approval. You cannot login until the admin approves your account.',
      );
    }
    if (approvalStatus != 'Approved') {
      throw Exception('Your driver account is not approved.');
    }

    return AuthResponseModel(
      user: _driverUser(driver, fallbackEmail: email),
      accessToken: _driverToken(driver),
      refreshToken: _driverToken(driver, refresh: true),
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    return _signUpViaWebApi(params);
  }

  Future<AuthResponseModel?> _tryLoginViaWebApi(LoginParams params) async {
    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      '$apiBaseUrl/api/drivers/login',
      data: {'email': params.email.trim().toLowerCase(), 'password': params.password},
    );
    final driver = Map<String, dynamic>.from(response.data ?? {});
    if (driver.isEmpty) throw Exception('Invalid driver login response.');

    final approvalStatus =
        driver['approval_status']?.toString().trim().isNotEmpty == true
        ? driver['approval_status'].toString()
        : 'Pending';

    if (approvalStatus == 'Pending') {
      throw Exception(
        'Waiting for approval. You cannot login until the admin approves your account.',
      );
    }
    if (approvalStatus != 'Approved') {
      throw Exception('Your driver account is not approved.');
    }

    return AuthResponseModel(
      user: _driverUser(driver),
      accessToken: _driverToken(driver),
      refreshToken: _driverToken(driver, refresh: true),
      requiresVerification: false,
    );
  }

  Future<AuthResponseModel> _signUpViaWebApi(SignUpParams params) async {
    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) {
      throw Exception(
        'Driver signup needs API_BASE_URL so the ID photo can be uploaded through the web app.',
      );
    }

    final fullName = _fullName(params);
    final bytes = params.personalIdBytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Personal ID photo is required.');
    }

    final data = dio.FormData.fromMap({
      'email': params.email.trim().toLowerCase(),
      'name': fullName.isEmpty ? params.email.trim() : fullName,
      'phone': params.phone?.trim() ?? '',
      'password': params.password,
      'telegram_username': params.telegramUsername?.trim() ?? '',
      'plate_number': params.plateNumber?.trim() ?? '',
      'vehicle_type': params.vehicleType ?? 'Bike',
      'status': 'Offline',
      'personal_id': dio.MultipartFile.fromBytes(
        bytes,
        filename: params.personalIdFileName ?? 'driver_id.jpg',
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '$apiBaseUrl/api/drivers',
      data: data,
    );
    final driver = Map<String, dynamic>.from(response.data ?? {});
    if (driver.isEmpty) throw Exception('Invalid driver signup response.');

    return AuthResponseModel(
      user: _driverUser(driver, fallbackEmail: params.email),
      requiresVerification: true,
      verificationKey: 'driver_approval_pending',
    );
  }

  dio.Dio get _dio =>
      dio.Dio(
          dio.BaseOptions(
            connectTimeout: Duration(milliseconds: _config.apiTimeout),
            receiveTimeout: Duration(milliseconds: _config.apiTimeout),
            sendTimeout: Duration(milliseconds: _config.apiTimeout),
            validateStatus: (status) => status != null && status < 500,
          ),
        )
        ..interceptors.add(
          dio.InterceptorsWrapper(
            onResponse: (response, handler) {
              if ((response.statusCode ?? 500) >= 400) {
                final data = response.data;
                final message = _apiErrorMessage(
                  data,
                  'Driver API request failed.',
                );
                handler.reject(
                  dio.DioException(
                    requestOptions: response.requestOptions,
                    response: response,
                    message: message,
                    type: dio.DioExceptionType.badResponse,
                  ),
                );
                return;
              }
              handler.next(response);
            },
          ),
        );

  String? get _apiBaseUrl {
    final baseUrl = _config.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (baseUrl.isEmpty || baseUrl.contains('your-webapp-domain')) {
      return null;
    }
    return baseUrl;
  }

  String _apiErrorMessage(Object? data, String fallback) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return fallback;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['error'] != null) {
          return decoded['error'].toString();
        }
      } catch (_) {
        if (trimmed.toLowerCase().contains('<!doctype')) {
          return 'Password recovery API was not found. Deploy the latest web app API changes.';
        }
        return trimmed.length > 240
            ? 'Driver API request failed. Check the deployed web app logs.'
            : trimmed;
      }
    }
    return fallback;
  }

  String _fullName(SignUpParams params) {
    final firstName = params.firstName?.trim() ?? '';
    final lastName = params.lastName?.trim() ?? '';
    return [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
  }

  @override
  Future<AuthResponseModel> verifyOtp(OtpVerificationParams params) async {
    throw Exception('Driver accounts are approved by the admin dashboard.');
  }

  @override
  Future<void> resendOtp(String verificationKey) async {
    throw Exception('Driver accounts are approved by the admin dashboard.');
  }

  @override
  Future<void> resetPassword(ResetPasswordParams params) async {
    final phone = params.phone.trim();
    if (phone.isEmpty) throw Exception('Enter your phone number.');

    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) {
      throw Exception(
        'Password recovery needs API_BASE_URL so the web app can send the SMS.',
      );
    }

    await _dio.post<Map<String, dynamic>>(
      '$apiBaseUrl/api/drivers/forgot-password',
      data: {'phone': phone},
    );
  }

  @override
  Future<void> verifyResetPassword(VerifyResetPasswordParams params) async {
    throw Exception(
      'Password reset is not configured for driver table accounts.',
    );
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    throw Exception(
      'Driver table accounts do not use Supabase Auth refresh tokens.',
    );
  }

  @override
  Future<void> logout() async {
    return;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw Exception('Driver table accounts use the cached local session.');
  }

  UserModel _driverUser(Map<String, dynamic> driver, {String? fallbackEmail}) {
    final name = driver['name']?.toString() ?? '';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final storedEmail = driver['email']?.toString().trim();

    return UserModel(
      id: driver['id']?.toString() ?? '',
      email: storedEmail?.isNotEmpty == true ? storedEmail! : fallbackEmail ?? '',
      isEmailVerified: false,
      firstName: nameParts.isEmpty ? name : nameParts.first,
      lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : null,
      phone: driver['phone']?.toString(),
    );
  }

  String _driverToken(Map<String, dynamic> driver, {bool refresh = false}) {
    final prefix = refresh ? 'driver_table_refresh' : 'driver_table_access';
    return '${prefix}_${driver['id']}_${DateTime.now().millisecondsSinceEpoch}';
  }
}
