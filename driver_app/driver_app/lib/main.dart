import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/config/supabase_runtime_config.dart';
import 'core/di/injection.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/preferences/app_preferences.dart';
import 'core/storage/storage_adapter.dart';
import 'core/storage/storage_service.dart';
import 'core/storage/clear_storage.dart';
import 'core/utils/constants/asset_constants/image_constants.dart';
import 'core/versioning/version_gate.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const _DriverBootstrapApp());
}

Future<AppPreferences> _initializeApp() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // Flutter builds should provide .env as an asset; validation below gives a clear setup error.
  }

  final supabaseConfig = await const SupabaseRuntimeConfigResolver().resolve();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseConfig.url,
    anonKey: supabaseConfig.anonKey,
  );

  // Configure dependency injection
  await configureDependencies();

  // Initialize storage service
  final storageService = getIt<IStorageService>();
  if (storageService is StorageService) {
    final logger = getIt<AppLogger>();
    await storageService.initialize(logger);

    // Check and clear storage on app version upgrade
    await ClearStorage.checkAndClearStorageOnUpgrade(storageService);
  }

  // Initialize Sentry
  final sentryService = getIt<SentryService>();
  await sentryService.initialize();

  final appPreferences = AppPreferences();
  await appPreferences.load();

  return appPreferences;
}

class _DriverBootstrapApp extends StatefulWidget {
  const _DriverBootstrapApp();

  @override
  State<_DriverBootstrapApp> createState() => _DriverBootstrapAppState();
}

class _DriverBootstrapAppState extends State<_DriverBootstrapApp> {
  late Future<AppPreferences> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _startApp();
  }

  Future<AppPreferences> _startApp() async {
    final results = await Future.wait<Object?>([
      _initializeApp(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    return results.first! as AppPreferences;
  }

  void _retry() {
    setState(() {
      _startupFuture = _startApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppPreferences>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DriverApp(preferences: snapshot.data!, showLaunch: false);
        }
        if (snapshot.hasError) {
          return _BootstrapErrorApp(
            appName: 'MotoBike Driver',
            error: snapshot.error,
            onRetry: _retry,
          );
        }
        return const _BootstrapSplashApp(
          appName: 'MotoBike Driver',
          tagline: 'Ready for smart deliveries',
        );
      },
    );
  }
}

class _BootstrapSplashApp extends StatelessWidget {
  const _BootstrapSplashApp({required this.appName, required this.tagline});

  final String appName;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _BootstrapSplashScreen(appName: appName, tagline: tagline),
    );
  }
}

class _BootstrapSplashScreen extends StatefulWidget {
  const _BootstrapSplashScreen({
    required this.appName,
    required this.tagline,
  });

  final String appName;
  final String tagline;

  @override
  State<_BootstrapSplashScreen> createState() => _BootstrapSplashScreenState();
}

class _BootstrapSplashScreenState extends State<_BootstrapSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoTurn;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _logoScale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _logoTurn = Tween<double>(begin: -0.025, end: 0.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF7F3),
                  Colors.white,
                  Color(0xFFFFE7DF),
                ],
              ),
            ),
            child: Center(
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  decorationColor: Colors.transparent,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _logoTurn.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 118,
                          height: 118,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.90),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.26 + (_controller.value * 0.14),
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              ImageConstants.appLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.motorcycle_rounded,
                                color: AppColors.primary,
                                size: 58,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeTransition(
                      opacity: _textOpacity,
                      child: Column(
                        children: [
                          Text(
                            widget.appName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.tagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                              decorationColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 150,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({
    required this.appName,
    required this.error,
    required this.onRetry,
  });

  final String appName;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primary,
                  size: 64,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '$appName could not start',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error?.toString() ?? 'Startup failed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text(
                    'TRY AGAIN',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DriverApp extends StatefulWidget {
  const DriverApp({
    required this.preferences,
    this.showLaunch = true,
    super.key,
  });

  final AppPreferences preferences;
  final bool showLaunch;

  @override
  State<DriverApp> createState() => _DriverAppState();
}

class _DriverAppState extends State<DriverApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final storageService = getIt<IStorageService>();
    _appRouter = AppRouter(storageService: storageService);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) =>
                  getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
            ),
          ],
          child: AppPreferencesScope(
            preferences: widget.preferences,
            child: AnimatedBuilder(
              animation: widget.preferences,
              builder: (context, _) {
                final platformBrightness = WidgetsBinding
                    .instance
                    .platformDispatcher
                    .platformBrightness;
                final isDark =
                    widget.preferences.themeMode == ThemeMode.dark ||
                    (widget.preferences.themeMode == ThemeMode.system &&
                        platformBrightness == Brightness.dark);

                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    statusBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    systemNavigationBarColor: isDark
                        ? AppColors.darkBackground
                        : AppColors.background,
                    systemNavigationBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                );

                return MaterialApp.router(
                  title: getIt<AppConfig>().appName,
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: widget.preferences.themeMode,
                  locale: Locale(widget.preferences.languageCode),
                  routerConfig: _appRouter.router,
                  builder: (context, widget) {
                    final appContent = _GlobalPullToRefresh(
                      child: MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaleFactor: 1.0),
                        child: widget!,
                      ),
                    );
                    return VersionGate(
                      app: 'driver',
                      config: getIt<AppConfig>(),
                      child: this.widget.showLaunch
                          ? _PremiumLaunchTransition(
                              appName: 'MotoBike Driver',
                              tagline: 'Ready for smart deliveries',
                              child: appContent,
                            )
                          : appContent,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _GlobalPullToRefresh extends StatefulWidget {
  const _GlobalPullToRefresh({required this.child});

  final Widget child;

  @override
  State<_GlobalPullToRefresh> createState() => _GlobalPullToRefreshState();
}

class _GlobalPullToRefreshState extends State<_GlobalPullToRefresh> {
  int _refreshKey = 0;

  Future<void> _handleRefresh() async {
    setState(() => _refreshKey++);
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: AppColors.primary,
      notificationPredicate: (notification) => notification.depth == 0,
      onRefresh: _handleRefresh,
      child: KeyedSubtree(key: ValueKey(_refreshKey), child: widget.child),
    );
  }
}

class _PremiumLaunchTransition extends StatefulWidget {
  const _PremiumLaunchTransition({
    required this.child,
    required this.appName,
    required this.tagline,
  });

  final Widget child;
  final String appName;
  final String tagline;

  @override
  State<_PremiumLaunchTransition> createState() =>
      _PremiumLaunchTransitionState();
}

class _PremiumLaunchTransitionState extends State<_PremiumLaunchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentScale;
  late final Animation<double> _appOpacity;
  late final Animation<double> _overlayOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoGlow;
  bool _showLaunch = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _contentOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 18),
          TweenSequenceItem(tween: ConstantTween(1), weight: 56),
          TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 16),
        ]).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
        );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.10, 0.36, curve: Curves.easeOutBack),
          ),
        );
    _contentScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.36, curve: Curves.easeOutBack),
      ),
    );
    _appOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1, curve: Curves.easeOutCubic),
    );
    _overlayOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1, curve: Curves.easeInOutCubic),
      ),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.34, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.34, curve: Curves.easeOutBack),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.14, end: 0.38).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.70, curve: Curves.easeInOutSine),
      ),
    );
    _controller
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showLaunch = false);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ColoredBox(
          color: background,
          child: Stack(
            children: [
              IgnorePointer(
                ignoring: _showLaunch,
                child: Opacity(
                  opacity: _showLaunch ? _appOpacity.value : 1,
                  child: widget.child,
                ),
              ),
              if (_showLaunch)
                FadeTransition(
                  opacity: _overlayOpacity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [
                                AppColors.darkBackground,
                                Color(0xFF201A24),
                                AppColors.darkBackground,
                              ]
                            : const [
                                Color(0xFFFFF7F3),
                                Colors.white,
                                Color(0xFFFFE7DF),
                              ],
                      ),
                    ),
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -84 + (_controller.value * 24),
                            right: -58,
                            child: _LaunchGlowOrb(
                              size: 190,
                              color: AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          Positioned(
                            bottom: -78,
                            left: -46 + (_controller.value * 28),
                            child: _LaunchGlowOrb(
                              size: 170,
                              color: AppColors.secondary.withValues(
                                alpha: 0.14,
                              ),
                            ),
                          ),
                          Center(
                            child: Opacity(
                              opacity: _contentOpacity.value,
                              child: SlideTransition(
                                position: _contentSlide,
                                child: Transform.scale(
                                  scale: _contentScale.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Transform.rotate(
                                        angle: _logoRotation.value,
                                        child: Transform.scale(
                                          scale: _logoScale.value,
                                          child: Container(
                                            width: 118,
                                            height: 118,
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: isDark ? 0.10 : 0.78,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(34),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: isDark ? 0.14 : 0.88,
                                                ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withValues(
                                                        alpha: _logoGlow.value,
                                                      ),
                                                  blurRadius: 32,
                                                  offset: const Offset(0, 16),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                              child: Image.asset(
                                                ImageConstants.appLogo,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                      Icons.motorcycle_rounded,
                                                      color: AppColors.primary,
                                                      size: 58,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      Text(
                                        widget.appName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 44,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                          decoration: TextDecoration.none,
                                          decorationColor: Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.tagline,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.textSecondary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.none,
                                          decorationColor: Colors.transparent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LaunchGlowOrb extends StatelessWidget {
  const _LaunchGlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
