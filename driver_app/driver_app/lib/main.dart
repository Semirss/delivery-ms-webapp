import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:driver_ui/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/preferences/app_preferences.dart';
import 'core/storage/storage_adapter.dart';
import 'core/storage/storage_service.dart';
import 'core/storage/clear_storage.dart';
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

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Create .env from .env.example and use the same Supabase project as the webapp.',
    );
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                        child: widget!,
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
