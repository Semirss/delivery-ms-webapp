import 'dart:async';

import 'package:driver_app/config/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final NavigationService _instance = NavigationService._internal();

  StatefulNavigationShell? _navigationShell;
  int? _pendingTabIndex;
  bool _pendingInitialLocation = false;
  bool _tabNavigationScheduled = false;
  int _navigationRetryCount = 0;

  static const int _maxNavigationRetries = 3;

  void setNavigationShell(StatefulNavigationShell shell) {
    _navigationShell = shell;
  }

  void navigateToTab(int index, {bool initialLocation = false}) {
    _pendingTabIndex = index;
    _pendingInitialLocation = initialLocation;
    _scheduleTabNavigation();
  }

  void _scheduleTabNavigation([
    Duration delay = const Duration(milliseconds: 16),
  ]) {
    if (_tabNavigationScheduled) return;

    _tabNavigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(delay, _flushTabNavigation);
    });
  }

  void _flushTabNavigation() {
    _tabNavigationScheduled = false;

    final shell = _navigationShell;
    final index = _pendingTabIndex;
    if (shell == null || index == null) return;

    final initialLocation = _pendingInitialLocation;
    _pendingTabIndex = null;
    _pendingInitialLocation = false;

    try {
      shell.goBranch(index, initialLocation: initialLocation);
      _navigationRetryCount = 0;
    } catch (error, stackTrace) {
      if (_isNavigatorLocked(error) &&
          _navigationRetryCount < _maxNavigationRetries) {
        _navigationRetryCount++;
        _pendingTabIndex = index;
        _pendingInitialLocation = initialLocation;
        _scheduleTabNavigation(const Duration(milliseconds: 48));
        return;
      }

      _navigationRetryCount = 0;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'navigation_service',
          context: ErrorDescription('while switching driver tabs'),
        ),
      );
    }
  }

  bool _isNavigatorLocked(Object error) {
    return error is AssertionError && error.toString().contains('_debugLocked');
  }

  void navigateToTabByRoute(BuildContext context, String routeName) {
    final tabIndex = _tabIndexForRoute(routeName);

    if (tabIndex != null) {
      navigateToTab(tabIndex);
    } else {
      GoRouter.of(context).goNamed(routeName);
    }
  }

  int? _tabIndexForRoute(String routeName) {
    if (routeName == AppRoutes.home.name) return 0;
    if (routeName == AppRoutes.notification.name) return 1;
    if (routeName == AppRoutes.earnings.name) return 2;
    if (routeName == AppRoutes.profile.name) return 3;
    return null;
  }
}
