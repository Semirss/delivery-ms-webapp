import '../../../../core/base/base_bloc.dart';

abstract class AuthEvent extends BaseEvent {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phone;

  const SignUpEvent({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, firstName, lastName, phone];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationKey;
  final String otp;

  const VerifyOtpEvent({
    required this.verificationKey,
    required this.otp,
  });

  @override
  List<Object> get props => [verificationKey, otp];
}

class ResendOtpEvent extends AuthEvent {
  final String verificationKey;

  const ResendOtpEvent({required this.verificationKey});

  @override
  List<Object> get props => [verificationKey];
}

class ResetPasswordEvent extends AuthEvent {
  final String email;

  const ResetPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class VerifyResetPasswordEvent extends AuthEvent {
  final String userId;
  final String otp;
  final String newPassword;

  const VerifyResetPasswordEvent({
    required this.userId,
    required this.otp,
    required this.newPassword,
  });

  @override
  List<Object> get props => [userId, otp, newPassword];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

