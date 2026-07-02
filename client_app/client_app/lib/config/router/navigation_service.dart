import 'dart:async';

import 'package:flutter/material.dart';
import 'package:client_app/config/router/app_routes.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  // Singleton pattern
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Reference to the StatefulNavigationShell
  StatefulNavigationShell? _navigationShell;
  VoidCallback? _homeAction;
  VoidCallback? _primaryDeliveryAction;
  int? _pendingTabIndex;
  bool _pendingInitialLocation = false;
  bool _tabNavigationScheduled = false;
  VoidCallback? _pendingTabAction;
  int _navigationRetryCount = 0;

  static const int _maxNavigationRetries = 3;

  // Set the navigation shell reference
  void setNavigationShell(StatefulNavigationShell shell) {
    _navigationShell = shell;
  }

  void setPrimaryDeliveryAction(VoidCallback action) {
    _primaryDeliveryAction = action;
  }

  void setHomeAction(VoidCallback action) {
    _homeAction = action;
  }

  void clearPrimaryDeliveryAction(VoidCallback action) {
    if (_primaryDeliveryAction == action) {
      _primaryDeliveryAction = null;
    }
  }

  void clearHomeAction(VoidCallback action) {
    if (_homeAction == action) {
      _homeAction = null;
    }
  }

  void triggerHomeAction() {
    navigateToTab(0, initialLocation: true, afterNavigation: _homeAction);
  }

  void triggerPrimaryDeliveryAction() {
    final action = _primaryDeliveryAction;
    if (action != null) {
      action();
      return;
    }
    navigateToTab(4, initialLocation: true);
  }

  // Navigate to a specific tab
  void navigateToTab(
    int index, {
    bool initialLocation = false,
    VoidCallback? afterNavigation,
  }) {
    _pendingTabIndex = index;
    _pendingInitialLocation = initialLocation;
    _pendingTabAction = afterNavigation;
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
    final afterNavigation = _pendingTabAction;
    _pendingTabIndex = null;
    _pendingInitialLocation = false;
    _pendingTabAction = null;

    try {
      shell.goBranch(index, initialLocation: initialLocation);
      _navigationRetryCount = 0;
    } catch (error, stackTrace) {
      if (_isNavigatorLocked(error) &&
          _navigationRetryCount < _maxNavigationRetries) {
        _navigationRetryCount++;
        _pendingTabIndex = index;
        _pendingInitialLocation = initialLocation;
        _pendingTabAction = afterNavigation;
        _scheduleTabNavigation(const Duration(milliseconds: 48));
        return;
      }

      _navigationRetryCount = 0;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'navigation_service',
          context: ErrorDescription('while switching app tabs'),
        ),
      );
      return;
    }

    if (afterNavigation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Timer(const Duration(milliseconds: 16), afterNavigation);
      });
    }
  }

  bool _isNavigatorLocked(Object error) {
    return error is AssertionError && error.toString().contains('_debugLocked');
  }

  // Navigate to a specific tab by route name
  void navigateToTabByRoute(BuildContext context, String routeName) {
    final router = GoRouter.of(context);

    // Map route names to tab indices
    int? tabIndex;

    if (routeName == AppRoutes.home.name) {
      tabIndex = 0;
    } else if (routeName == AppRoutes.activity.name ||
        routeName == AppRoutes.tracking.name) {
      tabIndex = 1;
    } else if (routeName == AppRoutes.food.name) {
      tabIndex = 2;
    } else if (routeName == AppRoutes.profile.name) {
      tabIndex = 3;
    } else if (routeName == AppRoutes.delivery.name) {
      tabIndex = 4;
    }

    if (tabIndex != null) {
      navigateToTab(tabIndex);
    } else {
      // If it's not a tab route, use normal navigation
      router.goNamed(routeName);
    }
  }
}
