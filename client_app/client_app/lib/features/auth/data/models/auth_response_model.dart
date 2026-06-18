import 'user_model.dart';

class AuthResponseModel {
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final String? verificationKey;
  final bool requiresVerification;
  final String? message;

  AuthResponseModel({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.verificationKey,
    this.requiresVerification = false,
    this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: json['user'] != null ? UserModel.fromJson(json['user'] as Map<String, dynamic>) : null,
      accessToken: json['access_token']?.toString() ?? json['accessToken']?.toString(),
      refreshToken: json['refresh_token']?.toString() ?? json['refreshToken']?.toString(),
      verificationKey: json['verification_key']?.toString() ?? json['verificationKey']?.toString(),
      requiresVerification: json['requires_verification'] as bool? ?? json['requiresVerification'] as bool? ?? false,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (verificationKey != null) 'verification_key': verificationKey,
      'requires_verification': requiresVerification,
      if (message != null) 'message': message,
    };
  }
}

