import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:injectable/injectable.dart';
import 'package:client_app/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/core/params/auth_params.dart';
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
class ClientTableAuthDataSourceImpl implements AuthRemoteDataSource {
  ClientTableAuthDataSourceImpl({AppConfig? config})
    : _config = config ?? AppConfig();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppConfig _config;

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final data = await _supabase.rpc<List<dynamic>>(
      'login_client',
      params: {
        'p_email': params.email.trim().toLowerCase(),
        'p_password': params.password,
      },
    );

    final user = UserModel.fromJson(_singleRow(data));

    return AuthResponseModel(
      user: user,
      accessToken: _clientToken(user),
      refreshToken: _clientToken(user, refresh: true),
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    final data = await _supabase.rpc<List<dynamic>>(
      'register_client',
      params: {
        'p_email': params.email.trim().toLowerCase(),
        'p_password': params.password,
        'p_first_name': params.firstName?.trim(),
        'p_last_name': params.lastName?.trim(),
        'p_phone': params.phone?.trim(),
      },
    );

    final user = UserModel.fromJson(_singleRow(data));

    return AuthResponseModel(
      user: user,
      accessToken: _clientToken(user),
      refreshToken: _clientToken(user, refresh: true),
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> verifyOtp(OtpVerificationParams params) async {
    throw Exception('OTP verification is not used for client table accounts');
  }

  @override
  Future<void> resendOtp(String verificationKey) async {
    throw Exception('OTP resend is not used for client table accounts');
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
      '$apiBaseUrl/api/clients/forgot-password',
      data: {
        'phone': phone,
        if (params.newPassword?.isNotEmpty == true)
          'newPassword': params.newPassword,
      },
    );
  }

  @override
  Future<void> verifyResetPassword(VerifyResetPasswordParams params) async {
    throw Exception('Password reset verification is not configured for client table accounts');
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    throw Exception('Client table accounts do not use Supabase Auth refresh tokens');
  }

  @override
  Future<void> logout() async {
    return;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw Exception('Client table accounts use the cached local session');
  }

  Map<String, dynamic> _singleRow(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Invalid client auth response');
  }

  String _clientToken(UserModel user, {bool refresh = false}) {
    final prefix = refresh ? 'client_table_refresh' : 'client_table_access';
    return '${prefix}_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
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
                  'Client API request failed.',
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
            ? 'Client API request failed. Check the deployed web app logs.'
            : trimmed;
      }
    }
    return fallback;
  }
}
