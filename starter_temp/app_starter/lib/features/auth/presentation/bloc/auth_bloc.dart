import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/params/auth_params.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/verify_reset_password_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../../../core/base/base_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final SignUpUseCase signUpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final VerifyResetPasswordUseCase verifyResetPasswordUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.signUpUseCase,
    required this.verifyOtpUseCase,
    required this.resendOtpUseCase,
    required this.resetPasswordUseCase,
    required this.verifyResetPasswordUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<SignUpEvent>(_onSignUp);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
    on<ResetPasswordEvent>(_onResetPassword);
    on<VerifyResetPasswordEvent>(_onVerifyResetPassword);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (authResult) {
        if (authResult.requiresVerification) {
          emit(AuthVerificationRequired(
            verificationKey: authResult.verificationKey ?? '',
          ));
        } else {
          emit(AuthAuthenticated(user: authResult.user));
        }
      },
    );
  }

  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signUpUseCase(
      SignUpParams(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (authResult) {
        if (authResult.requiresVerification) {
          emit(AuthVerificationRequired(
            verificationKey: authResult.verificationKey ?? '',
          ));
        } else {
          emit(AuthAuthenticated(user: authResult.user));
        }
      },
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyOtpUseCase(
      OtpVerificationParams(
        verificationKey: event.verificationKey,
        otp: event.otp,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (authResult) => emit(AuthAuthenticated(user: authResult.user)),
    );
  }

  Future<void> _onResendOtp(
    ResendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await resendOtpUseCase(event.verificationKey);
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (_) => emit(state), // Keep current state
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(email: event.email),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (_) => emit(const ResetPasswordSuccess()),
    );
  }

  Future<void> _onVerifyResetPassword(
    VerifyResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await verifyResetPasswordUseCase(
      VerifyResetPasswordParams(
        userId: event.userId,
        otp: event.otp,
        newPassword: event.newPassword,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (_) => emit(const ResetPasswordVerified()),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await logoutUseCase(NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.errMessage)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }
}

