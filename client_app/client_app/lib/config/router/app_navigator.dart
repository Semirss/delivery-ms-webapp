import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/core/storage/storage_adapter.dart';
import 'package:client_app/core/storage/storage_key_constants.dart';

import 'app_routes.dart';

abstract class AppNavigator {
  // Tab navigation
  void navigateToHomeTab();
  void navigateToProfileTab();

  // Auth and initialization
  void pushOnboardingScreen();
  void pushLanguageScreen();
  void pushLoginScreen();
  void pushSignUpScreen();
  void pushOtpVerificationScreen({String? verificationKey});
  void pushRestPasswordScreen();
  void pushRestVerificationScreen({String? userId, bool? isPhone});

  // Profile flow
  void pushProfileSelectionScreen();
  void pushCreateProfileScreen();
  void pushProfileSwitchScreen();
  void pushManageProfilesScreen();
  void pushAccountSettingsScreen();

  // Main navigation
  void pushHomeScreen();

  // User profile and settings
  void pushProfileScreen();
  void pushSettingScreen();
  void pushChangePinScreen();
  void pushPersonalDetailsScreen();
  void pushNotificationScreen();
  void pushSearchScreen();

  // Navigation helpers
  void pop();
  void popToRoot();
  void popUntil(String routeName);
  bool canPop();
  void goToHome();
  void replaceWith(String routeName);
}

class AppNavigatorImpl implements AppNavigator {
  AppNavigatorImpl(this.context);
  final BuildContext context;

  // Tab navigation
  @override
  void navigateToHomeTab() {
    NavigationService().triggerHomeAction();
  }

  @override
  void navigateToProfileTab() {
    NavigationService().navigateToTab(3);
  }

  @override
  void pushOnboardingScreen() {
    context.goNamed(AppRoutes.onBoarding.name);
  }

  @override
  void pushLanguageScreen() {
    context.pushNamed(AppRoutes.language.name);
  }

  @override
  void pushLoginScreen() {
    context.goNamed(AppRoutes.login.name);
  }

  @override
  void pushSignUpScreen() {
    context.pushNamed(AppRoutes.signUp.name);
  }

  @override
  void pushOtpVerificationScreen({String? verificationKey}) {
    if (verificationKey != null && verificationKey.isNotEmpty) {
      context.pushNamed(AppRoutes.otp.name, extra: verificationKey);
    } else {
      // Try to get verification key from storage
      final storageService = GetIt.instance<IStorageService>();
      final storedVerificationKey = storageService
          .getData(StorageKeys.verificationKey)
          ?.toString();
      context.pushNamed(AppRoutes.otp.name, extra: storedVerificationKey ?? '');
    }
  }

  @override
  void pushRestPasswordScreen() {
    context.pushNamed(AppRoutes.resetPassword.name);
  }

  @override
  void pushRestVerificationScreen({String? userId, bool? isPhone}) {
    final extra = <String, dynamic>{
      if (userId != null) 'userId': userId,
      if (isPhone != null) 'isPhone': isPhone,
    };
    context.pushNamed(
      AppRoutes.verifyReset.name,
      extra: extra.isNotEmpty ? extra : null,
    );
  }

  // Profile flow
  @override
  void pushProfileSelectionScreen() {
    context.goNamed(AppRoutes.profileSelection.name);
  }

  @override
  void pushCreateProfileScreen() {
    context.pushNamed(AppRoutes.createProfile.name);
  }

  @override
  void pushProfileSwitchScreen() {
    context.pushNamed(AppRoutes.profileSwitch.name);
  }

  @override
  void pushManageProfilesScreen() {
    context.pushNamed(AppRoutes.manageProfiles.name);
  }

  @override
  void pushAccountSettingsScreen() {
    context.pushNamed(AppRoutes.accountSettings.name);
  }

  // Main navigation
  @override
  void pushHomeScreen() {
    context.goNamed(AppRoutes.home.name);
  }

  // User profile and settings
  @override
  void pushProfileScreen() {
    NavigationService().navigateToTab(3);
  }

  @override
  void pushSettingScreen() {
    context.pushNamed(AppRoutes.setting.name);
  }

  @override
  void pushChangePinScreen() {
    context.pushNamed(AppRoutes.changePin.name);
  }

  @override
  void pushPersonalDetailsScreen() {
    context.pushNamed(AppRoutes.personalDetails.name);
  }

  @override
  void pushNotificationScreen() {
    context.pushNamed(AppRoutes.notification.name);
  }

  @override
  void pushSearchScreen() {
    context.pushNamed(AppRoutes.search.name);
  }

  // Navigation helpers
  @override
  void pop() {
    if (canPop()) {
      context.pop();
    } else {
      goToHome();
    }
  }

  @override
  void popToRoot() {
    while (canPop()) {
      context.pop();
    }
  }

  @override
  void popUntil(String routeName) {
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri
        .toString();

    if (currentLocation.contains(routeName)) {
      return;
    }

    while (canPop()) {
      context.pop();
      final newLocation = router.routerDelegate.currentConfiguration.uri
          .toString();
      if (newLocation.contains(routeName)) {
        break;
      }
    }
  }

  @override
  bool canPop() {
    return GoRouter.of(context).canPop();
  }

  @override
  void goToHome() {
    context.goNamed(AppRoutes.home.name);
  }

  @override
  void replaceWith(String routeName) {
    context.goNamed(routeName);
  }
}
