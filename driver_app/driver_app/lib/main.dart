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

void main() async {
  await _initializeApp();
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(DriverApp(preferences: appPreferences));
}

class DriverApp extends StatefulWidget {
  const DriverApp({required this.preferences, super.key});

  final AppPreferences preferences;

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
                    return VersionGate(
                      app: 'driver',
                      config: getIt<AppConfig>(),
                      child: _PremiumLaunchTransition(
                        appName: 'MotoBike Driver',
                        tagline: 'Ready for smart deliveries',
                        logoAsset: ImageConstants.appLogo,
                        child: _GlobalPullToRefresh(
                          child: MediaQuery(
                            data: MediaQuery.of(
                              context,
                            ).copyWith(textScaleFactor: 1.0),
                            child: widget!,
                          ),
                        ),
                      ),
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
      child: KeyedSubtree(
        key: ValueKey(_refreshKey),
        child: widget.child,
      ),
    );
  }
}

class _PremiumLaunchTransition extends StatefulWidget {
  const _PremiumLaunchTransition({
    required this.child,
    required this.appName,
    required this.tagline,
    required this.logoAsset,
  });

  final Widget child;
  final String appName;
  final String tagline;
  final String logoAsset;

  @override
  State<_PremiumLaunchTransition> createState() =>
      _PremiumLaunchTransitionState();
}

class _PremiumLaunchTransitionState extends State<_PremiumLaunchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _overlayOpacity;
  bool _showLaunch = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1550),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.08), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1), weight: 55),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.64, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _overlayOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1, curve: Curves.easeInOutCubic),
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

    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 420),
            opacity: _showLaunch ? 0 : 1,
            curve: Curves.easeOutCubic,
            child: widget.child,
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: 92,
                            height: 92,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 34,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Image.asset(widget.logoAsset),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      FadeTransition(
                        opacity: _contentOpacity,
                        child: SlideTransition(
                          position: _contentSlide,
                          child: Column(
                            children: [
                              AppText(
                                widget.appName,
                                variant: AppTextVariant.heading1,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                              const SizedBox(height: 8),
                              AppText(
                                widget.tagline,
                                variant: AppTextVariant.bodyMedium,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: 118,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.16,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                alignment: Alignment.centerLeft,
                                child: AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, _) {
                                    return FractionallySizedBox(
                                      widthFactor: _controller.value,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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
  }
}
