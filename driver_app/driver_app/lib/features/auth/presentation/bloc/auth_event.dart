import 'dart:typed_data';

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

class LoginWithGoogleEvent extends AuthEvent {
  const LoginWithGoogleEvent();
}

class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? telegramUsername;
  final String? plateNumber;
  final String? vehicleType;
  final Uint8List? personalIdBytes;
  final String? personalIdFileName;
  final String? personalIdMimeType;

  const SignUpEvent({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
    this.telegramUsername,
    this.plateNumber,
    this.vehicleType,
    this.personalIdBytes,
    this.personalIdFileName,
    this.personalIdMimeType,
  });

  @override
  List<Object?> get props => [
    email,
    password,
    firstName,
    lastName,
    phone,
    telegramUsername,
    plateNumber,
    vehicleType,
    personalIdBytes,
    personalIdFileName,
    personalIdMimeType,
  ];
}

class VerifyOtpEvent extends AuthEvent {
  final String verificationKey;
  final String otp;

  const VerifyOtpEvent({required this.verificationKey, required this.otp});

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
  final String phone;
  final String? newPassword;

  const ResetPasswordEvent({required this.phone, this.newPassword});

  @override
  List<Object?> get props => [phone, newPassword];
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
