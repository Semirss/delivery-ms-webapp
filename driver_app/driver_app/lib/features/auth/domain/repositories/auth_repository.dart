import 'package:dartz/dartz.dart';
import 'package:driver_app/core/errors/failure.dart';
import 'package:driver_app/core/params/auth_params.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResult>> login(LoginParams params);
  Future<Either<Failure, AuthResult>> loginWithGoogle();
  Future<Either<Failure, AuthResult>> signUp(SignUpParams params);
  Future<Either<Failure, AuthResult>> verifyOtp(OtpVerificationParams params);
  Future<Either<Failure, void>> resendOtp(String verificationKey);
  Future<Either<Failure, void>> resetPassword(ResetPasswordParams params);
  Future<Either<Failure, void>> verifyResetPassword(
    VerifyResetPasswordParams params,
  );
  Future<Either<Failure, AuthResult>> refreshToken(RefreshTokenParams params);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, UserEntity?>> getCachedUser();
}

class AuthResult {
  final UserEntity user;
  final String accessToken;
  final String? refreshToken;
  final bool requiresVerification;
  final String? verificationKey;

  AuthResult({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.requiresVerification = false,
    this.verificationKey,
  });
}
