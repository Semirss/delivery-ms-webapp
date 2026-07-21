import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart' as dio;
import 'package:driver_app/core/config/app_config.dart';
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
  Future<UserModel> getCurrentUser();
}

@Injectable(as: AuthRemoteDataSource)
class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  SupabaseAuthDataSourceImpl({AppConfig? config})
    : _config = config ?? AppConfig();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AppConfig _config;
  static const String _googleRedirectUrl = 'motobike-driver://login-callback/';
  static const String _supportPhone = '+251 931 323 328';
  static const String _supportEmail = 'support@motobike.app';

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final email = params.email.trim().toLowerCase();
    if (email.isEmpty) throw Exception('Enter your driver email.');
    if (params.password.isEmpty) throw Exception('Please enter your password.');

    try {
      final apiLogin = await _tryLoginViaWebApi(
        LoginParams(email: email, password: params.password),
      );
      if (apiLogin != null) return apiLogin;
    } on dio.DioException catch (error) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode >= 500 || statusCode == 0) rethrow;
    }

    final rows = await _supabase
        .from('drivers')
        .select()
        .ilike('email', email)
        .limit(1);
    final driverRows = List<Map<String, dynamic>>.from(rows);
    final data = driverRows.isEmpty ? null : driverRows.first;

    if (data == null) {
      throw Exception(
        'No driver account found with this email. Ask admin to add this email to your driver profile.',
      );
    }

    final driver = Map<String, dynamic>.from(data);
    if (driver['password']?.toString() != params.password) {
      throw Exception('Invalid email or password.');
    }

    final approvalStatus = _driverApprovalStatus(driver);
    if (!_isApprovedStatus(approvalStatus)) {
      throw Exception(_approvalRequiredMessage(approvalStatus));
    }

    return AuthResponseModel(
      user: _driverUser(driver, fallbackEmail: email),
      accessToken: _driverToken(driver),
      refreshToken: _driverToken(driver, refresh: true),
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> loginWithGoogle() async {
    final sessionUser = _supabase.auth.currentUser;
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

      final user = await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => throw TimeoutException(
          'Google sign-in was not completed. Please try again.',
        ),
      );
      return _driverFromGoogleUser(user);
    } finally {
      await subscription.cancel();
    }
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

    final rows = await _supabase
        .from('drivers')
        .select()
        .ilike('email', email)
        .limit(1);
    final driverRows = List<Map<String, dynamic>>.from(rows);
    final data = driverRows.isEmpty ? null : driverRows.first;

    if (data == null) {
      await _supabase.auth.signOut();
      throw Exception(
        'No driver account exists for this Google email. Please submit a driver application first.',
      );
    }

    final driver = Map<String, dynamic>.from(data);
    final approvalStatus = _driverApprovalStatus(driver);
    if (!_isApprovedStatus(approvalStatus)) {
      await _supabase.auth.signOut();
      throw Exception(_approvalRequiredMessage(approvalStatus));
    }

    return AuthResponseModel(
      user: _driverUser(driver, fallbackEmail: email),
      accessToken: _driverToken(driver),
      refreshToken: _driverToken(driver, refresh: true),
      requiresVerification: false,
    );
  }

  Future<AuthResponseModel?> _tryLoginViaWebApi(LoginParams params) async {
    final apiBaseUrl = _apiBaseUrl;
    if (apiBaseUrl == null) return null;

    final response = await _dio.post<Map<String, dynamic>>(
      '$apiBaseUrl/api/drivers/login',
      data: {
        'email': params.email.trim().toLowerCase(),
        'password': params.password,
      },
    );
    final driver = Map<String, dynamic>.from(response.data ?? {});
    if (driver.isEmpty) throw Exception('Invalid driver login response.');

    final approvalStatus = _driverApprovalStatus(driver);
    if (!_isApprovedStatus(approvalStatus)) {
      throw Exception(_approvalRequiredMessage(approvalStatus));
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
    final email = params.email.trim().toLowerCase();
    final phone = params.phone?.trim() ?? '';
    final telegram = params.telegramUsername?.trim() ?? '';
    final plate = params.plateNumber?.trim() ?? '';
    if (fullName.isEmpty) throw Exception('Please enter your full name.');
    if (email.isEmpty) throw Exception('Please enter your email.');
    if (phone.isEmpty) throw Exception('Please enter your phone number.');
    if (telegram.isEmpty)
      throw Exception('Please enter your Telegram username.');
    if (plate.isEmpty) throw Exception('Please enter your plate number.');
    if (params.password.isEmpty) throw Exception('Please enter your password.');
    if (params.password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final bytes = params.personalIdBytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Personal ID photo is required.');
    }

    final data = dio.FormData.fromMap({
      'email': email,
      'name': fullName,
      'phone': phone,
      'password': params.password,
      'telegram_username': telegram,
      'plate_number': plate,
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

  String _driverApprovalStatus(Map<String, dynamic> driver) {
    final status = driver['approval_status']?.toString().trim();
    return status?.isNotEmpty == true ? status! : 'Pending';
  }

  bool _isApprovedStatus(String status) =>
      status.trim().toLowerCase() == 'approved';

  String _approvalRequiredMessage(String approvalStatus) {
    final normalizedStatus = approvalStatus.trim();
    final statusText = normalizedStatus.toLowerCase() == 'pending'
        ? 'Your driver application is still waiting for admin approval.'
        : 'Your driver account is $normalizedStatus. Admin approval is required before login.';
    return 'Approval required first. $statusText If this takes too long, contact admin at $_supportPhone or $_supportEmail.';
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
      await _resetPasswordDirectly(params);
      return;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$apiBaseUrl/api/drivers/forgot-password',
        data: {
          'phone': phone,
          if (params.newPassword?.isNotEmpty == true)
            'newPassword': params.newPassword,
        },
      );
      final next = response.data?['next']?.toString();
      if (params.newPassword?.isNotEmpty == true && next != 'login') {
        await _resetPasswordDirectly(params);
      }
    } on dio.DioException catch (error) {
      final message = error.message ?? '';
      if (message.contains('No driver account found')) {
        await _resetPasswordDirectly(params);
        return;
      }
      rethrow;
    }
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
    await _supabase.auth.signOut();
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
      email: storedEmail?.isNotEmpty == true
          ? storedEmail!
          : fallbackEmail ?? '',
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

  Future<void> _resetPasswordDirectly(ResetPasswordParams params) async {
    final normalizedPhone = _normalizeEthiopianPhone(params.phone);
    if (normalizedPhone.isEmpty) throw Exception('Enter your phone number.');

    final data = await _supabase
        .from('drivers')
        .select('id, phone')
        .not('phone', 'is', null);

    final drivers = (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    Map<String, dynamic>? matched;

    for (final driver in drivers) {
      if (_normalizeEthiopianPhone(driver['phone']) == normalizedPhone) {
        matched = driver;
        break;
      }
    }

    if (matched == null) {
      throw Exception('No driver account found for this phone number.');
    }

    final newPassword = params.newPassword ?? '';
    if (newPassword.isEmpty) return;
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    await _supabase
        .from('drivers')
        .update({'password': newPassword})
        .eq('id', matched['id'].toString());
  }

  String _normalizeEthiopianPhone(Object? value) {
    final digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.isEmpty) return '';

    if (digits.length == 12 &&
        digits.startsWith('251') &&
        (digits[3] == '7' || digits[3] == '9')) {
      return '0${digits.substring(3)}';
    }

    if (digits.length == 9 && (digits[0] == '7' || digits[0] == '9')) {
      return '0$digits';
    }

    if (digits.length == 10 &&
        digits.startsWith('0') &&
        (digits[1] == '7' || digits[1] == '9')) {
      return digits;
    }

    return digits;
  }
}
