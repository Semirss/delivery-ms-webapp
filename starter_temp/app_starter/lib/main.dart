import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui/app_ui.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'config/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/di/injection.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/storage/storage_adapter.dart';
import 'core/storage/storage_service.dart';
import 'core/storage/clear_storage.dart';
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
    // .env file might not exist, continue with defaults
  }

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

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Sentry and run app
  await SentryFlutter.init(
    (options) => options.dsn = getIt<AppConfig>().sentryDsn,
    appRunner: () => runApp(const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
          child: MaterialApp.router(
            title: getIt<AppConfig>().appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.lightTheme,
            routerConfig: _appRouter.router,
            builder: (context, widget) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: widget!,
              );
            },
          ),
        );
      },
    );
  }
}
