import 'package:driver_app/config/router/app_routes.dart';
import 'package:driver_app/config/router/navigation_service.dart';
import 'package:driver_app/core/storage/storage_adapter.dart';
import 'package:driver_app/core/storage/storage_key_constants.dart';
import 'package:driver_app/core/utils/functions/base_functions/data_functions.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:driver_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:driver_app/features/auth/presentation/screens/login_screen.dart';
import 'package:driver_app/features/auth/presentation/screens/otp_screen.dart';
import 'package:driver_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:driver_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:driver_app/features/auth/presentation/screens/verify_reset_password_screen.dart';
import 'package:driver_app/features/home/presentation/screens/home_screen.dart';
import 'package:driver_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:driver_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/driver_documents_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/driver_statistics_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/earnings_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/personal_details_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:driver_app/features/profile/presentation/screens/support_screen.dart';
import 'package:driver_app/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final IStorageService storageService;

  AppRouter({required this.storageService});

  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> notificationsTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> earningsTabNavigatorKey =
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
          // Notifications tab
          StatefulShellBranch(
            navigatorKey: notificationsTabNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.notification.name,
                path: AppRoutes.notification.path,
                pageBuilder: (context, state) => getPage(
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, authState) {
                      if (authState is AuthUnauthenticated) {
                        context.goNamed(AppRoutes.login.name);
                      }
                    },
                    child: const NotificationsScreen(),
                  ),
                  state: state,
                ),
              ),
            ],
          ),
          // Earnings tab
          StatefulShellBranch(
            navigatorKey: earningsTabNavigatorKey,
            routes: [
              GoRoute(
                name: AppRoutes.earnings.name,
                path: AppRoutes.earnings.path,
                pageBuilder: (context, state) => getPage(
                  child: BlocListener<AuthBloc, AuthState>(
                    listener: (context, authState) {
                      if (authState is AuthUnauthenticated) {
                        context.goNamed(AppRoutes.login.name);
                      }
                    },
                    child: const EarningsScreen(showBackButton: false),
                  ),
                  state: state,
                ),
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

      // Profile detail routes
      GoRoute(
        name: AppRoutes.personalDetails.name,
        path: AppRoutes.personalDetails.path,
        pageBuilder: (context, state) =>
            getPage(child: const PersonalDetailsScreen(), state: state),
      ),
      GoRoute(
        name: AppRoutes.driverDocuments.name,
        path: AppRoutes.driverDocuments.path,
        pageBuilder: (context, state) =>
            getPage(child: const DriverDocumentsScreen(), state: state),
      ),
      GoRoute(
        name: AppRoutes.driverStatistics.name,
        path: AppRoutes.driverStatistics.path,
        pageBuilder: (context, state) =>
            getPage(child: const DriverStatisticsScreen(), state: state),
      ),
      GoRoute(
        name: AppRoutes.support.name,
        path: AppRoutes.support.path,
        pageBuilder: (context, state) =>
            getPage(child: const SupportScreen(), state: state),
      ),
      GoRoute(
        name: AppRoutes.privacy.name,
        path: AppRoutes.privacy.path,
        pageBuilder: (context, state) =>
            getPage(child: const PrivacyPolicyScreen(), state: state),
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
          AppRoutes.notification.path,
          AppRoutes.earnings.path,
          AppRoutes.profile.path,
          AppRoutes.personalDetails.path,
          AppRoutes.driverDocuments.path,
          AppRoutes.driverStatistics.path,
          AppRoutes.support.path,
          AppRoutes.privacy.path,
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
              color: AppColors.textSecondary,
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
    return NoTransitionPage(key: state.pageKey, child: child);
  }
}

// Main screen with driver bottom navigation.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final bottomGap = MediaQuery.viewPaddingOf(context).bottom + 10;
    final reservedBottom = bottomGap + _DriverBottomNavBar.height + 8;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.goNamed(AppRoutes.login.name);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            Positioned.fill(
              bottom: reservedBottom,
              child: navigationShell,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomGap,
              child: _DriverBottomNavBar(
                currentIndex: navigationShell.currentIndex,
                onHomeTap: () => NavigationService().navigateToTab(0),
                onAlertsTap: () => NavigationService().navigateToTab(1),
                onEarningsTap: () => NavigationService().navigateToTab(2),
                onProfileTap: () => NavigationService().navigateToTab(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverBottomNavBar extends StatelessWidget {
  const _DriverBottomNavBar({
    required this.currentIndex,
    required this.onHomeTap,
    required this.onAlertsTap,
    required this.onEarningsTap,
    required this.onProfileTap,
  });

  static const double height = 68;

  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onEarningsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: context.isAppDark ? 0.12 : 0.06),
      context.appSurface,
    );
    final borderColor = Color.alphaBlend(
      colorScheme.primary.withValues(alpha: context.isAppDark ? 0.24 : 0.14),
      context.appBorder,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isAppDark ? 0.32 : 0.13,
                ),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                _DriverNavItem(
                  icon: Icons.map_rounded,
                  label: 'Home',
                  selected: currentIndex == 0,
                  onTap: onHomeTap,
                ),
                _DriverNavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  selected: currentIndex == 1,
                  onTap: onAlertsTap,
                ),
                _DriverNavItem(
                  icon: Icons.payments_rounded,
                  label: 'Earnings',
                  selected: currentIndex == 2,
                  onTap: onEarningsTap,
                ),
                _DriverNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  selected: currentIndex == 3,
                  onTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverNavItem extends StatelessWidget {
  const _DriverNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : context.appTextSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 23),
                  const SizedBox(height: 3),
                  AppText(
                    label,
                    variant: AppTextVariant.labelSmall,
                    color: color,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  bottom: 1,
                  child: Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
