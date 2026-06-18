import 'package:app_starter/core/databases/api/api_consumer.dart';
import 'package:app_starter/core/databases/api/end_points.dart';
import 'package:app_starter/core/params/auth_params.dart';
import 'package:injectable/injectable.dart';
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
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiConsumer apiConsumer;

  AuthRemoteDataSourceImpl({required this.apiConsumer});

  @override
  Future<AuthResponseModel> login(LoginParams params) async {
    try {
      final response = await apiConsumer.post(
        EndPoints.login,
        data: params.toJson(),
      );
      return AuthResponseModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> signUp(SignUpParams params) async {
    try {
      final response = await apiConsumer.post(
        EndPoints.signUp,
        data: params.toJson(),
      );
      return AuthResponseModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> verifyOtp(OtpVerificationParams params) async {
    try {
      final response = await apiConsumer.post(
        EndPoints.verifyOtp,
        data: params.toJson(),
      );
      return AuthResponseModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resendOtp(String verificationKey) async {
    try {
      await apiConsumer.post(
        EndPoints.resendOtp,
        data: {'verification_key': verificationKey},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(ResetPasswordParams params) async {
    try {
      await apiConsumer.post(
        EndPoints.resetPassword,
        data: params.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> verifyResetPassword(VerifyResetPasswordParams params) async {
    try {
      await apiConsumer.post(
        EndPoints.verifyResetPassword,
        data: params.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthResponseModel> refreshToken(RefreshTokenParams params) async {
    try {
      final response = await apiConsumer.post(
        EndPoints.refreshToken,
        data: params.toJson(),
      );
      return AuthResponseModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiConsumer.post(EndPoints.logout);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiConsumer.get(EndPoints.me);
      return UserModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}

