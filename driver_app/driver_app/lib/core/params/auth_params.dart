// ignore_for_file: sort_constructors_first

import 'dart:typed_data';

class LoginParams {
  LoginParams({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class SignUpParams {
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

  SignUpParams({
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

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (phone != null) 'phone': phone,
    if (telegramUsername != null) 'telegram_username': telegramUsername,
    if (plateNumber != null) 'plate_number': plateNumber,
    if (vehicleType != null) 'vehicle_type': vehicleType,
  };
}

class OtpVerificationParams {
  final String verificationKey;
  final String otp;

  OtpVerificationParams({required this.verificationKey, required this.otp});

  Map<String, dynamic> toJson() => {
    'verification_key': verificationKey,
    'otp': otp,
  };
}

class ResetPasswordParams {
  final String email;

  ResetPasswordParams({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

class VerifyResetPasswordParams {
  final String userId;
  final String otp;
  final String newPassword;

  VerifyResetPasswordParams({
    required this.userId,
    required this.otp,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'otp': otp,
    'new_password': newPassword,
  };
}

class RefreshTokenParams {
  final String refreshToken;

  RefreshTokenParams({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
