import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:driver_app/core/config/app_config.dart';
import 'package:driver_app/core/connection/network_info.dart';
import 'package:driver_app/core/databases/cache/cache_helper.dart';
import 'package:driver_app/core/logging/app_logger.dart';
import 'package:driver_app/core/monitoring/sentry_service.dart';
import 'package:driver_app/core/storage/storage_adapter.dart';
import 'package:driver_app/core/storage/storage_service.dart';
import 'package:driver_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:driver_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:driver_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:driver_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/signup_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:driver_app/features/auth/domain/usecases/verify_reset_password_usecase.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<AppConfig>()) return;

  final cacheHelper = CacheHelper();
  await cacheHelper.init();

  getIt
    ..registerSingleton<AppConfig>(AppConfig())
    ..registerSingleton<Connectivity>(Connectivity())
    ..registerSingleton<CacheHelper>(cacheHelper)
    ..registerSingleton<SentryService>(SentryService(getIt<AppConfig>()))
    ..registerSingleton<AppLogger>(
      AppLogger(getIt<AppConfig>(), getIt<SentryService>()),
    )
    ..registerSingleton<IStorageService>(StorageService())
    ..registerSingleton<NetworkInfo>(NetworkInfoImpl(getIt<Connectivity>()))
    ..registerSingleton<AuthRemoteDataSource>(
      SupabaseAuthDataSourceImpl(config: getIt<AppConfig>()),
    )
    ..registerSingleton<AuthLocalDataSource>(
      AuthLocalDataSourceImpl(cacheHelper: getIt<CacheHelper>()),
    )
    ..registerSingleton<AuthRepository>(
      AuthRepositoryImpl(
        logger: getIt<AppLogger>(),
        sentryService: getIt<SentryService>(),
        remoteDataSource: getIt<AuthRemoteDataSource>(),
        localDataSource: getIt<AuthLocalDataSource>(),
        networkInfo: getIt<NetworkInfo>(),
      ),
    )
    ..registerFactory(() => LoginUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => LoginWithGoogleUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => SignUpUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => VerifyOtpUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => ResendOtpUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => ResetPasswordUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => VerifyResetPasswordUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => LogoutUseCase(getIt<AuthRepository>()))
    ..registerFactory(() => GetCurrentUserUseCase(getIt<AuthRepository>()))
    ..registerFactory(
      () => AuthBloc(
        loginUseCase: getIt<LoginUseCase>(),
        loginWithGoogleUseCase: getIt<LoginWithGoogleUseCase>(),
        signUpUseCase: getIt<SignUpUseCase>(),
        verifyOtpUseCase: getIt<VerifyOtpUseCase>(),
        resendOtpUseCase: getIt<ResendOtpUseCase>(),
        resetPasswordUseCase: getIt<ResetPasswordUseCase>(),
        verifyResetPasswordUseCase: getIt<VerifyResetPasswordUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      ),
    );
}
