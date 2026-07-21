import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:client_app/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client_app/core/params/auth_params.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginParams params);
  Future<AuthResponseModel> loginWithGoogle();
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
  static const String _googleRedirectUrl = 'motobike-client://login-callback/';

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty) throw Exception('Please enter your email.');
    if (params.password.isEmpty) throw Exception('Please enter your password.');

    final data = await _supabase.rpc<List<dynamic>>(
      'login_client',
      params: {'p_email': email, 'p_password': params.password},
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
  Future<AuthResponseModel> loginWithGoogle() async {
    final sessionUser = _supabase.auth.currentUser;
    if (sessionUser != null) {
      return _clientFromGoogleUser(sessionUser);
    }

    final completer = Completer<User>();
    late final StreamSubscription<AuthState> subscription;
    subscription = _supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null && !completer.isCompleted) {
        completer.complete(user);
      }
    });

    try {
      final launched = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : _googleRedirectUrl,
      );
      if (!launched) {
        throw Exception('Could not open Google sign-in. Please try again.');
      }

      final user = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException(
          'Google sign-in was not completed. Please try again.',
        ),
      );
      return _clientFromGoogleUser(user);
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    final email = params.email.trim().toLowerCase();
    final password = params.password;
    final firstName = params.firstName?.trim() ?? '';
    final lastName = params.lastName?.trim() ?? '';
    final phone = params.phone?.trim() ?? '';
    if (firstName.isEmpty) throw Exception('Please enter your first name.');
    if (lastName.isEmpty) throw Exception('Please enter your last name.');
    if (email.isEmpty) throw Exception('Please enter your email.');
    if (password.isEmpty) throw Exception('Please enter your password.');
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    if (phone.isEmpty) throw Exception('Please enter your phone number.');

    final data = await _supabase.rpc<List<dynamic>>(
      'register_client',
      params: {
        'p_email': email,
        'p_password': password,
        'p_first_name': firstName,
        'p_last_name': lastName,
        'p_phone': phone,
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

  Future<AuthResponseModel> _clientFromGoogleUser(User googleUser) async {
    final email = googleUser.email?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      throw Exception('Google did not return an email address.');
    }

    final data = await _clientRowForEmail(email);

    if (data == null) {
      await _supabase.auth.signOut();
      throw Exception(
        'No client account exists for this Google email. Please sign up first.',
      );
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(data));
    return AuthResponseModel(
      user: user,
      accessToken: _clientToken(user),
      refreshToken: _clientToken(user, refresh: true),
      requiresVerification: false,
    );
  }

  Future<Map<String, dynamic>?> _clientRowForEmail(String email) async {
    try {
      final data = await _supabase.rpc<dynamic>(
        'get_client_by_email_for_oauth',
        params: {'p_email': email},
      );
      final row = _singleNullableRow(data);
      if (row != null) return row;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      if (!lower.contains('could not find the function') &&
          !lower.contains('404') &&
          !lower.contains('not found')) {
        rethrow;
      }
    }

    final rows = await _supabase
        .from('clients')
        .select()
        .ilike('email', email)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(rows);
    return list.isEmpty ? null : list.first;
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
    throw Exception(
      'Password reset verification is not configured for client table accounts',
    );
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    throw Exception(
      'Client table accounts do not use Supabase Auth refresh tokens',
    );
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
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

  Map<String, dynamic>? _singleNullableRow(dynamic data) {
    if (data is List) {
      if (data.isEmpty) return null;
      return Map<String, dynamic>.from(data.first as Map);
    }
    if (data is Map && data.isNotEmpty) {
      return Map<String, dynamic>.from(data);
    }
    return null;
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
