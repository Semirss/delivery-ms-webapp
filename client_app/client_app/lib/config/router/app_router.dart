import 'package:client_app/config/router/app_routes.dart';
import 'package:client_app/config/router/navigation_service.dart';
import 'package:client_app/core/storage/storage_adapter.dart';
import 'package:client_app/core/storage/storage_key_constants.dart';
import 'package:client_app/core/utils/functions/base_functions/data_functions.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:client_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:client_app/features/auth/presentation/screens/login_screen.dart';
import 'package:client_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:client_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:client_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:client_app/features/auth/presentation/screens/verify_reset_password_screen.dart';
import 'package:client_app/features/home/presentation/screens/home_screen.dart';
import 'package:client_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:client_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:client_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:client_app/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final IStorageService storageService;

  AppRouter({required this.storageService});

  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> profileTabNavigatorKey =
      GlobalKey<NavigatorState>();

  bool _isRedirecting = false;
  int _redirectCount = 0;
  static const int _maxRedirects = 3;

  bool get isAuthenticatedSync {
    try {
      final accessToken = storageService.getData(StorageKeys.accessToken);
      final user = storageService.getData(StorageKeys.user);
      return _isUsableToken(accessToken) &&
          user != null &&
          user.toString().trim().isNotEmpty;
    } catch (e) {
      outlog('Error checking auth status: $e');
      return false;
    }
  }

  bool _isUsableToken(Object? value) {
    final token = value?.toString().trim() ?? '';
    if (token.isEmpty) return false;

    final lower = token.toLowerCase();
    return !lower.startsWith('mock_') &&
        !lower.contains('placeholder') &&
        !lower.contains('your_');
  }

  bool get hasSelectedProfileSync {
    try {
      final selectedProfileId = storageService.getData(
        StorageKeys.selectedProfile,
      );
      final hasProfile =
          selectedProfileId != null && selectedProfileId.toString().isNotEmpty;
      outlog(
        'Router - Has selected profile: $hasProfile (ID: $selectedProfileId)',
      );
      return hasProfile;
    } catch (e) {
      outlog('Error checking selected profile: $e');
      return false;
    }
  }

  bool get isOnboardingCompletedSync {
    try {
      final onboardingStateValue = storageService.getData(
        StorageKeys.onboardingState,
      );
      if (onboardingStateValue == null) {
        return false;
      }

      // Support both enum string and boolean for backward compatibility
      if (onboardingStateValue is bool) {
        return onboardingStateValue;
      }

      final stateString = onboardingStateValue.toString();
      return stateString == 'completed';
    } catch (e) {
      outlog('Error checking onboarding status: $e');
      return false;
    }
  }

  late final GoRouter router = GoRouter(
    navigatorKey: parentNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    initialLocation: AppRoutes.onBoarding.path,
    routes: [
      // Main shell route for bottom navigation
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        builder: (context, state, navigationShell) {
          // Set navigation shell in NavigationService
          NavigationService().setNavigationShell(navigationShell);
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            navigatorKey: homeTabNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.home.name,
                path: AppRoutes.home.path,
                pageBuilder: (context, state) => getPage(
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, authState) {
                      if (authState is AuthUnauthenticated) {
                        context.goNamed(AppRoutes.login.name);
                      }
                    },
                    child: const HomeScreen(),
                  ),
                  state: state,
                ),
                routes: [
                  GoRoute(
                    name: AppRoutes.search.name,
                    path: AppRoutes.search.path,
                    pageBuilder: (context, state) =>
                        getPage(child: const SearchScreen(), state: state),
                  ),
                ],
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            navigatorKey: profileTabNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.profile.name,
                path: AppRoutes.profile.path,
                pageBuilder: (context, state) => getPage(
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, authState) {
                      if (authState is AuthUnauthenticated) {
                        context.goNamed(AppRoutes.login.name);
                      }
                    },
                    child: const ProfileScreen(),
                  ),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),

      // Auth routes
      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        pageBuilder: (context, state) => getPage(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthAuthenticated) {
                context.goNamed(AppRoutes.home.name);
              } else if (authState is AuthVerificationRequired) {
                context.goNamed(
                  AppRoutes.otp.name,
                  extra: authState.verificationKey,
                );
              }
            },
            child: const LoginScreen(),
          ),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.signUp.name,
        path: AppRoutes.signUp.path,
        pageBuilder: (context, state) => getPage(
          child: BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthAuthenticated) {
                context.goNamed(AppRoutes.home.name);
              } else if (authState is AuthVerificationRequired) {
                context.goNamed(
                  AppRoutes.otp.name,
                  extra: authState.verificationKey,
                );
              }
            },
            child: const SignUpScreen(),
          ),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.otp.name,
        path: AppRoutes.otp.path,
        pageBuilder: (context, state) {
          final verificationKey = state.extra as String?;
          return getPage(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is AuthAuthenticated) {
                  context.goNamed(AppRoutes.home.name);
                }
              },
              child: OtpScreen(verificationKey: verificationKey),
            ),
            state: state,
          );
        },
      ),
      GoRoute(
        name: AppRoutes.resetPassword.name,
        path: AppRoutes.resetPassword.path,
        pageBuilder: (context, state) =>
            getPage(child: const ResetPasswordScreen(), state: state),
      ),
      GoRoute(
        name: AppRoutes.verifyReset.name,
        path: AppRoutes.verifyReset.path,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return getPage(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, authState) {
                if (authState is ResetPasswordVerified) {
                  context.goNamed(AppRoutes.login.name);
                }
              },
              child: VerifyResetPasswordScreen(
                userId: extra?['userId'] as String?,
                isPhone: extra?['isPhone'] as bool?,
              ),
            ),
            state: state,
          );
        },
      ),

      // Placeholder routes for profile screens
      GoRoute(
        name: AppRoutes.personalDetails.name,
        path: AppRoutes.personalDetails.path,
        pageBuilder: (context, state) => getPage(
          child: Scaffold(
            appBar: AppAppBar(titleText: 'Personal Details'),
            body: const Center(child: AppText('Personal details screen')),
          ),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.notification.name,
        path: AppRoutes.notification.path,
        pageBuilder: (context, state) => getPage(
          child: const NotificationsScreen(),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.changePin.name,
        path: AppRoutes.changePin.path,
        pageBuilder: (context, state) => getPage(
          child: Scaffold(
            appBar: AppAppBar(titleText: 'Change PIN'),
            body: const Center(child: AppText('Change PIN screen')),
          ),
          state: state,
        ),
      ),
      GoRoute(
        name: AppRoutes.setting.name,
        path: AppRoutes.setting.path,
        pageBuilder: (context, state) => getPage(
          child: Scaffold(
            appBar: AppAppBar(titleText: 'Settings'),
            body: const Center(child: AppText('Settings screen')),
          ),
          state: state,
        ),
      ),

      GoRoute(
        name: AppRoutes.onBoarding.name,
        path: AppRoutes.onBoarding.path,
        pageBuilder: (context, state) =>
            getPage(child: const OnboardingScreen(), state: state),
      ),
    ],
    redirect: (context, state) {
      // Prevent redirect loops
      if (_isRedirecting) {
        _redirectCount++;
        if (_redirectCount > _maxRedirects) {
          outlog('Redirect loop detected - resetting');
          _redirectCount = 0;
          _isRedirecting = false;
          return AppRoutes.login.path;
        }
        return null;
      }

      final location = state.matchedLocation;
      final authPages = [
        AppRoutes.login.path,
        AppRoutes.signUp.path,
        AppRoutes.otp.path,
        AppRoutes.resetPassword.path,
        AppRoutes.verifyReset.path,
        AppRoutes.onBoarding.path,
      ];
      final isInAuthPage = authPages.contains(location);

      outlog('Router - Location: $location');

      try {
        _isRedirecting = true;

        // Check onboarding status first
        final isOnboardingCompleted = isOnboardingCompletedSync;
        final isOnboardingPage = location == AppRoutes.onBoarding.path;

        // If onboarding not completed and not on onboarding page, redirect to onboarding
        if (!isOnboardingCompleted && !isOnboardingPage) {
          outlog('Onboarding not completed - redirecting to onboarding');
          return AppRoutes.onBoarding.path;
        }

        // If onboarding completed and on onboarding page, go home when authenticated
        if (isOnboardingCompleted && isOnboardingPage) {
          if (isAuthenticatedSync) {
            outlog(
              'Onboarding completed and authenticated - redirecting to home',
            );
            return AppRoutes.home.path;
          }
          outlog('Onboarding completed - redirecting to login');
          return AppRoutes.login.path;
        }

        // Protected routes that require authentication
        final protectedRoutes = [
          AppRoutes.home.path,
          AppRoutes.profile.path,
          AppRoutes.personalDetails.path,
          AppRoutes.notification.path,
          AppRoutes.changePin.path,
          AppRoutes.setting.path,
        ];

        // If user is authenticated and on auth pages, redirect to home
        if (isAuthenticatedSync && isInAuthPage && !isOnboardingPage) {
          outlog('Authenticated user on auth page - redirecting to home');
          return AppRoutes.home.path;
        }

        // If user is not authenticated and on protected routes, redirect to login
        if (!isAuthenticatedSync &&
            protectedRoutes.any((route) => location.startsWith(route))) {
          outlog('Redirecting unauthenticated user to login from: $location');
          return AppRoutes.login.path;
        }

        return null;
      } finally {
        _isRedirecting = false;
        _redirectCount = 0;
      }
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: context.appBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            AppText('Page not found', variant: AppTextVariant.heading2),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'The page you are looking for does not exist.',
              variant: AppTextVariant.bodyMedium,
              color: context.appTextSecondary,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.primary(
              label: 'Go Home',
              icon: Icons.home,
              onPressed: () {
                context.goNamed(AppRoutes.home.name);
              },
            ),
          ],
        ),
      ),
    ),
  );

  static Page<dynamic> getPage({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

// Main screen with bottom navigation
class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.goNamed(AppRoutes.login.name);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _ModernBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
        ),
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  const _ModernBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: _ModernBottomNavItem(
                selected: currentIndex == 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _ModernBottomNavItem(
                selected: currentIndex == 1,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
                onTap: () => onTap(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernBottomNavItem extends StatelessWidget {
  const _ModernBottomNavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.primary : context.appTextSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                color: foreground,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: foreground,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: selected ? 18 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
