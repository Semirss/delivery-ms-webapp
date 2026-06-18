// ignore_for_file: sort_constructors_first

class LoginParams {

  LoginParams({required this.email, required this.password});
  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class SignUpParams {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? phone;

  SignUpParams({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phone != null) 'phone': phone,
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

  Map<String, dynamic> toJson() => {
        'email': email,
      };
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

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

