import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that provides consistent back button handling
class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackPressed;
  final bool canPop;
  final String? fallbackRoute;

  const NavigationWrapper({
    super.key,
    required this.child,
    this.onBackPressed,
    this.canPop = true,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          if (onBackPressed != null) {
            onBackPressed!();
          } else if (fallbackRoute != null) {
            GoRouter.of(context).goNamed(fallbackRoute!);
          } else {
            GoRouter.of(context).goNamed('home');
          }
        }
      },
      child: child,
    );
  }
}

/// Extension to make navigation easier
extension NavigationExtension on BuildContext {
  void safeGoBack({String? fallbackRoute}) {
    if (GoRouter.of(this).canPop()) {
      pop();
    } else {
      goNamed(fallbackRoute ?? 'home');
    }
  }

  void goToHomeTab() {
    goNamed('home');
  }

  void popToRoot() {
    while (GoRouter.of(this).canPop()) {
      pop();
    }
  }
}
