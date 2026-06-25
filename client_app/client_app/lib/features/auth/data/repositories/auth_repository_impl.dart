import 'package:dartz/dartz.dart';
import 'package:client_app/core/base/base_repository.dart';
import 'package:client_app/core/connection/network_info.dart';
import 'package:client_app/core/errors/expentions.dart';
import 'package:client_app/core/errors/failure.dart';
import 'package:client_app/core/params/auth_params.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required super.logger,
    required super.sentryService,
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AuthResult>> login(LoginParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.login(params);

        // Cache tokens and user if authentication successful
        if (response.user == null || response.accessToken == null) {
          return Left(ServerFailure('Invalid login response from server'));
        }
        await localDataSource.cacheAccessToken(response.accessToken!);
        if (response.refreshToken != null) {
          await localDataSource.cacheRefreshToken(response.refreshToken!);
        }
        await localDataSource.cacheUser(response.user!);
        await localDataSource.cacheLoginTimestamp(
          DateTime.now().millisecondsSinceEpoch,
        );
        if (response.verificationKey != null) {
          await localDataSource.cacheVerificationKey(response.verificationKey!);
        }

        return Right(
          AuthResult(
            user: response.user!,
            accessToken: response.accessToken!,
            refreshToken: response.refreshToken ?? '',
            requiresVerification: response.requiresVerification,
            verificationKey: response.verificationKey,
          ),
        );
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(_friendlyError(e)));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> signUp(SignUpParams params) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.signUp(params);

        if (!response.requiresVerification &&
            (response.user == null || response.accessToken == null)) {
          return Left(ServerFailure('Invalid sign up response from server'));
        }

        // Cache verification key if provided
        if (response.verificationKey != null) {
          await localDataSource.cacheVerificationKey(response.verificationKey!);
        }

        if (response.accessToken != null) {
          await localDataSource.cacheAccessToken(response.accessToken!);
        }
        if (response.refreshToken != null) {
          await localDataSource.cacheRefreshToken(response.refreshToken!);
        }
        if (response.user != null) {
          await localDataSource.cacheUser(response.user!);
        }
        if (!response.requiresVerification) {
          await localDataSource.cacheLoginTimestamp(
            DateTime.now().millisecondsSinceEpoch,
          );
        }

        return Right(
          AuthResult(
            user: response.user ?? UserEntity(id: '', email: params.email),
            accessToken: response.accessToken ?? '',
            refreshToken: response.refreshToken ?? '',
            requiresVerification: response.requiresVerification,
            verificationKey: response.verificationKey,
          ),
        );
      } on ServerException catch (e) {
        logger.error('Sign up failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Sign up error', e, stackTrace);
        return Left(ServerFailure(_friendlyError(e)));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> verifyOtp(
    OtpVerificationParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.verifyOtp(params);

        // Cache tokens and user on successful verification
        if (response.accessToken != null) {
          await localDataSource.cacheAccessToken(response.accessToken!);
          if (response.refreshToken != null) {
            await localDataSource.cacheRefreshToken(response.refreshToken!);
          }
          if (response.user != null) {
            await localDataSource.cacheUser(response.user!);
          }
          await localDataSource.cacheLoginTimestamp(
            DateTime.now().millisecondsSinceEpoch,
          );
        }

        if (response.user == null || response.accessToken == null) {
          return Left(ServerFailure('Invalid response from server'));
        }

        return Right(
          AuthResult(
            user: response.user!,
            accessToken: response.accessToken!,
            refreshToken: response.refreshToken ?? '',
            requiresVerification: false,
            verificationKey: null,
          ),
        );
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resendOtp(String verificationKey) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resendOtp(verificationKey);
        return Right(null);
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    ResetPasswordParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.resetPassword(params);
        return Right(null);
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetPassword(
    VerifyResetPasswordParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.verifyResetPassword(params);
        return Right(null);
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AuthResult>> refreshToken(
    RefreshTokenParams params,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.refreshToken(params);

        if (response.accessToken != null) {
          await localDataSource.cacheAccessToken(response.accessToken!);
          if (response.refreshToken != null) {
            await localDataSource.cacheRefreshToken(response.refreshToken!);
          }
        }

        if (response.user == null || response.accessToken == null) {
          return Left(ServerFailure('Invalid response from server'));
        }

        return Right(
          AuthResult(
            user: response.user!,
            accessToken: response.accessToken!,
            refreshToken: response.refreshToken ?? '',
            requiresVerification: false,
          ),
        );
      } on ServerException catch (e) {
        logger.error('Login failed', e, StackTrace.current);
        return Left(ServerFailure(e.errorModel.errorMessage));
      } catch (e, stackTrace) {
        logger.error('Login error', e, stackTrace);
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    final cachedUser = await localDataSource.getCachedUser();
    final cachedToken = await localDataSource.getCachedAccessToken();
    final hasToken = _isUsableToken(cachedToken);

    if (cachedUser != null && hasToken) {
      return Right(cachedUser);
    }

    return Left(CacheFailure('No cached client session'));
  }

  @override
  Future<Either<Failure, UserEntity?>> getCachedUser() async {
    try {
      final user = await localDataSource.getCachedUser();
      return Right(user);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  bool _isUsableToken(String? value) {
    final token = value?.trim() ?? '';
    if (token.isEmpty) return false;

    final lower = token.toLowerCase();
    return !lower.startsWith('mock_') &&
        !lower.contains('placeholder') &&
        !lower.contains('your_');
  }

  String _friendlyError(Object error) {
    var message = error.toString();
    message = message.replaceFirst('Exception: ', '');
    if (message.contains('duplicate key') || message.contains('already exists')) {
      return 'A client account already exists for this email';
    }
    if (message.contains('Invalid email or password')) {
      return 'Invalid email or password';
    }
    if (message.contains('login_client') ||
        message.contains('register_client') ||
        message.contains('Could not find the function') ||
        message.contains('gen_salt') ||
        message.contains('crypt(') ||
        message.contains('pgcrypto')) {
      return 'Client auth database is not installed. Run supabase/schema_v4_app_versions.sql in Supabase.';
    }
    return message;
  }
}
