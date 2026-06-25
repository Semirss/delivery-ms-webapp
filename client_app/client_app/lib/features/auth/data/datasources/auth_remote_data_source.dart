import 'package:injectable/injectable.dart';
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
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final data = await _supabase.rpc(
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
    final data = await _supabase.rpc(
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
    throw Exception('Password reset is not configured for client table accounts');
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
}
