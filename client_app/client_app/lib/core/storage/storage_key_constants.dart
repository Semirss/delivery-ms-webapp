// Updated StorageKeys enum with profile keys
enum StorageKeys {
  username,
  email,
  userId,
  phone,
  password,
  user,
  country,
  accessToken,
  refreshToken,
  version,
  verificationKey,
  pendingUserData,
  loginTimestamp,
  onboardingState,
  userProfile,
  selectedProfile,
  appLanguage,
}

extension StorageKeysExtension on StorageKeys {
  String get name {
    switch (this) {
      case StorageKeys.username:
        return 'username';
      case StorageKeys.email:
        return 'email';
      case StorageKeys.userId:
        return 'userId';
      case StorageKeys.phone:
        return 'phone';
      case StorageKeys.password:
        return 'password';
      case StorageKeys.user:
        return 'user';
      case StorageKeys.country:
        return 'country';
      case StorageKeys.accessToken:
        return 'accessToken';
      case StorageKeys.refreshToken:
        return 'refreshToken';
      case StorageKeys.version:
        return 'version';
      case StorageKeys.verificationKey:
        return 'verificationKey';
      case StorageKeys.pendingUserData:
        return 'pendingUserData';
      case StorageKeys.loginTimestamp:
        return 'loginTimestamp';
      case StorageKeys.onboardingState:
        return 'onboardingState';
      case StorageKeys.userProfile:
        return 'userProfile';
      case StorageKeys.selectedProfile:
        return 'selectedProfile';
      case StorageKeys.appLanguage:
        return 'appLanguage';
    }
  }
}
