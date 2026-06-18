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

  // Set the navigation shell reference
  void setNavigationShell(StatefulNavigationShell shell) {
    _navigationShell = shell;
  }

  // Navigate to a specific tab
  void navigateToTab(int index) {
    if (_navigationShell != null) {
      _navigationShell!.goBranch(index, initialLocation: index == 0);
    }
  }

  // Navigate to a specific tab by route name
  void navigateToTabByRoute(BuildContext context, String routeName) {
    final router = GoRouter.of(context);

    // Map route names to tab indices
    int? tabIndex;

    if (routeName == AppRoutes.home.name) {
      tabIndex = 0;
    } else if (routeName == AppRoutes.profile.name) {
      tabIndex = 1;
    }

    if (tabIndex != null) {
      navigateToTab(tabIndex);
    } else {
      // If it's not a tab route, use normal navigation
      router.goNamed(routeName);
    }
  }
}
