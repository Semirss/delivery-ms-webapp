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
class SupabaseAuthDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    final response = await _supabase.auth.signInWithPassword(
      email: params.email,
      password: params.password,
    );

    final user = response.user;
    if (user == null) throw Exception('Login failed: no user returned');

    return AuthResponseModel(
      user: UserModel(
        id: user.id,
        email: user.email ?? '',
        isEmailVerified: user.emailConfirmedAt != null,
        firstName: user.userMetadata?['first_name'] as String?,
        lastName: user.userMetadata?['last_name'] as String?,
        phone: user.phone,
      ),
      accessToken: response.session?.accessToken,
      requiresVerification: false,
    );
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    final response = await _supabase.auth.signUp(
      email: params.email,
      password: params.password,
      data: {
        'first_name': params.firstName,
        'last_name': params.lastName,
        'phone': params.phone,
      },
    );

    final user = response.user;
    if (user == null) throw Exception('Sign up failed');

    // Supabase may require email verification
    final requiresVerification = response.session == null;

    return AuthResponseModel(
      user: UserModel(
        id: user.id,
        email: user.email ?? '',
        isEmailVerified: user.emailConfirmedAt != null,
        firstName: params.firstName,
        lastName: params.lastName,
        phone: params.phone,
      ),
      requiresVerification: requiresVerification,
      verificationKey: user.email, // used as reference for OTP verification
    );
  }

  @override
  Future<AuthResponseModel> verifyOtp(OtpVerificationParams params) async {
    // verificationKey stores the email
    final response = await _supabase.auth.verifyOTP(
      email: params.verificationKey,
      token: params.otp,
      type: OtpType.signup,
    );

    final user = response.user;
    if (user == null) throw Exception('OTP verification failed');

    return AuthResponseModel(
      user: UserModel(
        id: user.id,
        email: user.email ?? '',
        isEmailVerified: true,
        firstName: user.userMetadata?['first_name'] as String?,
        lastName: user.userMetadata?['last_name'] as String?,
        phone: user.phone,
      ),
      accessToken: response.session?.accessToken,
    );
  }

  @override
  Future<void> resendOtp(String verificationKey) async {
    await _supabase.auth.resend(type: OtpType.signup, email: verificationKey);
  }

  @override
  Future<void> resetPassword(ResetPasswordParams params) async {
    await _supabase.auth.resetPasswordForEmail(params.email);
  }

  @override
  Future<void> verifyResetPassword(VerifyResetPasswordParams params) async {
    // In Supabase flow, user clicks email link which sets session, then updates password
    await _supabase.auth.updateUser(UserAttributes(password: params.newPassword));
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    final response = await _supabase.auth.refreshSession();
    final user = response.user;
    if (user == null) throw Exception('Session refresh failed');
    return AuthResponseModel(
      user: UserModel(id: user.id, email: user.email ?? '', isEmailVerified: true),
      accessToken: response.session?.accessToken,
    );
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      isEmailVerified: user.emailConfirmedAt != null,
      firstName: user.userMetadata?['first_name'] as String?,
      lastName: user.userMetadata?['last_name'] as String?,
      phone: user.phone,
    );
  }
}
