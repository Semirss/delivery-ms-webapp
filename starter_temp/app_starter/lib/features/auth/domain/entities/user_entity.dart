class UserEntity {
  final String id;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;

  UserEntity({
    required this.id,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
  });
}

