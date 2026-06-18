import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.email,
    super.phone,
    super.firstName,
    super.lastName,
    super.profileImage,
    super.isEmailVerified,
    super.isPhoneVerified,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      firstName: json['first_name']?.toString() ?? json['firstName']?.toString(),
      lastName: json['last_name']?.toString() ?? json['lastName']?.toString(),
      profileImage: json['profile_image']?.toString() ?? json['profileImage']?.toString(),
      isEmailVerified: json['is_email_verified'] as bool? ?? json['isEmailVerified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? json['isPhoneVerified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (phone != null) 'phone': phone,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (profileImage != null) 'profile_image': profileImage,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

