import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart' as dio;
import 'package:driver_app/core/config/app_config.dart';
import 'package:driver_app/core/operations/driver_operations_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:driver_app/core/params/auth_params.dart';
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
  Future<void> deleteAccount(DeleteAccountParams params);
}

@Injectable(as: AuthRemoteDataSource)
class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  SupabaseAuthDataSourceImpl({AppConfig? config})
    : _config = config ?? AppConfig();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppConfig _config;
  static const String _googleRedirectUrl = 'motobike-driver://login-callback/';

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final identifier = _loginIdentifier(params.email);
    if (identifier.isEmpty) {
      throw Exception('Enter your driver email or phone number.');
    }
    if (params.password.isEmpty) throw Exception('Please enter your password.');

    final base = _apiBaseUrl;
    if (base == null)
      throw Exception(
        'Sign-in is temporarily unavailable. Please try again later or contact support.',
      );
    final response = await _dio.post<Map<String, dynamic>>(
      '$base/api/drivers/login',
      data: {'identifier': identifier, 'password': params.password},
    );
    final driver = Map<String, dynamic>.from(response.data ?? {});
    final token = _secureDriverToken(driver);

    return AuthResponseModel(
      user: _driverUser(
        driver,
        fallbackEmail: _isEmailIdentifier(identifier) ? identifier : null,
      ),
      accessToken: token,
      refreshToken: '',
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> loginWithGoogle() async {
    final sessionUser = _currentGoogleUser();
    if (sessionUser != null) {
      return _driverFromGoogleUser(sessionUser);
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

      final user = await _waitForGoogleUser(completer);
      return _driverFromGoogleUser(user);
    } finally {
      await subscription.cancel();
    }
  }

  User? _currentGoogleUser() {
    return _supabase.auth.currentUser ?? _supabase.auth.currentSession?.user;
  }

  Future<User> _waitForGoogleUser(Completer<User> authChange) async {
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      final user = _currentGoogleUser();
      if (user != null) return user;
      if (authChange.isCompleted) return authChange.future;

      await Future.any<Object?>([
        authChange.future,
        Future<void>.delayed(const Duration(milliseconds: 250)),
      ]);
    }

    throw TimeoutException(
      'Google sign-in was not completed. Please try again.',
    );
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    return _signUpViaWebApi(params);
  }

  Future<AuthResponseModel> _driverFromGoogleUser(User googleUser) async {
    final email = googleUser.email?.trim().toLowerCase() ?? '';
    if (email.isEmpty) {
      throw Exception('Google did not return an email address.');
    }

    final base = _apiBaseUrl;
    final googleToken = _supabase.auth.currentSession?.accessToken;
    if (base == null || googleToken == null)
      throw Exception('Please sign in with Google again.');
    final response = await _dio.post<Map<String, dynamic>>(
      '$base/api/drivers/session',
      options: dio.Options(headers: {'Authorization': 'Bearer $googleToken'}),
    );
    final data = response.data;

    if (data == null) {
      await _supabase.auth.signOut();
      throw Exception(
        'No driver account was found for this Google email. Please register first or contact support.',
      );
    }

    final driver = Map<String, dynamic>.from(data);

    return AuthResponseModel(
      user: _driverUser(driver, fallbackEmail: email),
      accessToken: _secureDriverToken(driver),
      refreshToken: '',
      requiresVerification: false,
    );
  }

  String _loginIdentifier(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';
    if (_isEmailIdentifier(raw)) return raw.toLowerCase();

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^09\d{8}$').hasMatch(digits)) {
      throw Exception(
        'Use an Ethiopian phone number starting with 09, for example 0912345678',
      );
    }
    return _normalizeEthiopianPhone(raw);
  }

  bool _isEmailIdentifier(String value) => value.contains('@');

  String _secureDriverToken(Map<String, dynamic> driver) {
    final id = driver['id']?.toString().trim() ?? '';
    final token = driver['access_token']?.toString().trim() ?? '';
    final parts = token.split('.');
    if (id.isEmpty || parts.length != 3 || parts.any((part) => part.isEmpty)) {
      throw Exception(
        'Driver API response is missing a signed access token or driver ID.',
      );
    }
    return token;
  }

  Future<AuthResponseModel> _signUpViaWebApi(SignUpParams params) async {
    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) {
      throw Exception(
        'Registration is temporarily unavailable. Please try again later or contact support.',
      );
    }

    final fullName = _fullName(params);
    final email = params.email.trim().toLowerCase();
    final phone = params.phone?.trim() ?? '';
    final telegram = params.telegramUsername?.trim() ?? '';
    final plate = params.plateNumber?.trim() ?? '';
    if (fullName.isEmpty) throw Exception('Please enter your full name.');
    if (email.isEmpty) throw Exception('Please enter your email.');
    if (telegram.isEmpty)
      throw Exception('Please enter your Telegram username.');
    if (plate.isEmpty) throw Exception('Please enter your plate number.');
    if (params.password.isEmpty) throw Exception('Please enter your password.');
    if (params.password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final bytes = params.personalIdBytes;

    final formFields = <String, dynamic>{
      'email': email,
      'name': fullName,
      'password': params.password,
      'telegram_username': telegram,
      'plate_number': plate,
      'vehicle_type': params.vehicleType ?? 'Bike',
      'status': 'Offline',
      if (phone.isNotEmpty) 'phone': phone,
    };

    if (bytes != null && bytes.isNotEmpty) {
      formFields['personal_id'] = dio.MultipartFile.fromBytes(
        bytes,
        filename: params.personalIdFileName ?? 'driver_id.jpg',
      );
    }

    final data = dio.FormData.fromMap(formFields);

    final response = await _dio.post<Map<String, dynamic>>(
      '$apiBaseUrl/api/drivers',
      data: data,
    );
    final driver = Map<String, dynamic>.from(response.data ?? {});
    if (driver.isEmpty) {
      throw Exception(
        'Registration is temporarily unavailable. Please try again later or contact support.',
      );
    }

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
          return 'This service is temporarily unavailable. Please try again later or contact support.';
        }
        return trimmed.length > 240
            ? 'This service is temporarily unavailable. Please try again later or contact support.'
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
    throw Exception(
      'Password reset is handled by support after account ownership is verified.',
    );
  }

  @override
  Future<void> verifyResetPassword(VerifyResetPasswordParams params) async {
    throw Exception('Password reset is unavailable. Please contact support.');
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    throw Exception('Please sign in again to continue.');
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> deleteAccount(DeleteAccountParams params) async {
    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) {
      throw Exception(
        'Account deletion is temporarily unavailable. Please try again later or contact support.',
      );
    }

    final userId = params.userId.trim();
    if (userId.isEmpty) throw Exception('No account is signed in.');

    await DriverOperationsApi().request(
      '/api/drivers/${Uri.encodeComponent(userId)}',
      method: 'DELETE',
    );

    await logout();
  }

  UserModel _driverUser(Map<String, dynamic> driver, {String? fallbackEmail}) {
    final name = driver['name']?.toString() ?? '';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final storedEmail = driver['email']?.toString().trim();

    return UserModel(
      id: driver['id']?.toString() ?? '',
      email: storedEmail?.isNotEmpty == true
          ? storedEmail!
          : fallbackEmail ?? '',
      isEmailVerified: false,
      firstName: nameParts.isEmpty ? name : nameParts.first,
      lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : null,
      phone: driver['phone']?.toString(),
    );
  }

  String _normalizeEthiopianPhone(Object? value) {
    final digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return '';

    if (digits.length == 12 && digits.startsWith('251') && digits[3] == '9') {
      return '0${digits.substring(3)}';
    }

    if (digits.length == 9 && digits[0] == '9') {
      return '0$digits';
    }

    if (digits.length == 10 && digits.startsWith('0') && digits[1] == '9') {
      return digits;
    }

    return digits;
  }
}
