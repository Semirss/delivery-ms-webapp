import 'package:dartz/dartz.dart';
import 'package:driver_app/core/errors/failure.dart';
import 'package:driver_app/core/params/auth_params.dart';
import 'package:driver_app/features/auth/domain/entities/user_entity.dart';
import 'package:driver_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_app/features/auth/domain/usecases/delete_account_usecase.dart';
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
import 'package:driver_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(LoginParams(email: '', password: ''));
  });

  late MockAuthRepository repository;
  late AuthBloc bloc;
  final user = UserEntity(id: 'driver-1', email: 'driver@example.com');

  setUp(() {
    repository = MockAuthRepository();
    bloc = AuthBloc(
      loginUseCase: LoginUseCase(repository),
      loginWithGoogleUseCase: LoginWithGoogleUseCase(repository),
      signUpUseCase: SignUpUseCase(repository),
      verifyOtpUseCase: VerifyOtpUseCase(repository),
      resendOtpUseCase: ResendOtpUseCase(repository),
      resetPasswordUseCase: ResetPasswordUseCase(repository),
      verifyResetPasswordUseCase: VerifyResetPasswordUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      deleteAccountUseCase: DeleteAccountUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
    );
  });

  tearDown(() async => bloc.close());

  test('password sign-in requests online only once', () async {
    when(() => repository.login(any())).thenAnswer(
      (_) async => Right<Failure, AuthResult>(
        AuthResult(user: user, accessToken: 'signed-token'),
      ),
    );

    bloc.add(const LoginEvent(email: 'driver@example.com', password: 'secret'));
    await bloc.stream.firstWhere((state) => state is AuthAuthenticated);

    expect(bloc.takeAutoOnlineOnNextHome(), isTrue);
    expect(bloc.takeAutoOnlineOnNextHome(), isFalse);
  });

  test('restoring a saved login does not request online again', () async {
    when(
      () => repository.getCurrentUser(),
    ).thenAnswer((_) async => Right<Failure, UserEntity>(user));

    bloc.add(const CheckAuthStatusEvent());
    await bloc.stream.firstWhere((state) => state is AuthAuthenticated);

    expect(bloc.takeAutoOnlineOnNextHome(), isFalse);
  });
}
