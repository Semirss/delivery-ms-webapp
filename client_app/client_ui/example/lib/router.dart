import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/buttons_screen.dart';
import 'screens/form_fields_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/dialogs_screen.dart';
import 'screens/modals_screen.dart';
import 'screens/feedback_screen.dart';

class AppRouter {
  final VoidCallback onThemeToggle;
  final ThemeMode currentThemeMode;

  AppRouter({required this.onThemeToggle, required this.currentThemeMode});

  GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            HomeScreen(
              onThemeToggle: onThemeToggle,
              currentThemeMode: currentThemeMode,
            ),
          ),
        ),
        GoRoute(
          path: '/buttons',
          name: 'buttons',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const ButtonsScreen()),
        ),
        GoRoute(
          path: '/form-fields',
          name: 'form-fields',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context,
            state,
            const FormFieldsScreen(),
          ),
        ),
        GoRoute(
          path: '/cards',
          name: 'cards',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const CardsScreen()),
        ),
        GoRoute(
          path: '/dialogs',
          name: 'dialogs',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const DialogsScreen()),
        ),
        GoRoute(
          path: '/modals',
          name: 'modals',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const ModalsScreen()),
        ),
        GoRoute(
          path: '/feedback',
          name: 'feedback',
          pageBuilder: (context, state) =>
              _buildPageWithTransition(context, state, const FeedbackScreen()),
        ),
      ],
    );
  }

  CustomTransitionPage _buildPageWithTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition from right to left
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var offsetAnimation = animation.drive(tween);

        // Fade transition
        var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}
