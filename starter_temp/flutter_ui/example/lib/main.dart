import 'package:flutter/material.dart';
import 'package:flutter_ui/app_ui.dart';
import 'router.dart';

void main() {
  runApp(const AppUIExampleApp());
}

class AppUIExampleApp extends StatefulWidget {
  const AppUIExampleApp({super.key});

  @override
  State<AppUIExampleApp> createState() => _AppUIExampleAppState();
}

class _AppUIExampleAppState extends State<AppUIExampleApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _initRouter();
  }

  void _initRouter() {
    _appRouter = AppRouter(
      onThemeToggle: _toggleTheme,
      currentThemeMode: _themeMode,
    );
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // Preserve current route on hot reload
    _initRouter();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App UI Example',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routerConfig: _appRouter.createRouter(),
    );
  }
}
