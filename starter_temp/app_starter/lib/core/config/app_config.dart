import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

@singleton
class AppConfig {
  static const String _environment = 'ENVIRONMENT';
  static const String _appName = 'APP_NAME';
  static const String _apiBaseUrl = 'API_BASE_URL';
  static const String _apiTimeout = 'API_TIMEOUT';
  static const String _sentryDsn = 'SENTRY_DSN';
  static const String _sentryEnvironment = 'SENTRY_ENVIRONMENT';
  static const String _enableLogging = 'ENABLE_LOGGING';
  static const String _enableChuckInterceptor = 'ENABLE_CHUCK_INTERCEPTOR';

  String get environment => dotenv.get(_environment, fallback: 'development');
  String get appName => dotenv.get(_appName, fallback: 'Flutter Boilerplate');
  String get apiBaseUrl => dotenv.get(_apiBaseUrl);
  int get apiTimeout => int.parse(dotenv.get(_apiTimeout, fallback: '30000'));
  String get sentryDsn => dotenv.get(_sentryDsn, fallback: '');
  String get sentryEnvironment => dotenv.get(_sentryEnvironment, fallback: 'development');
  bool get enableLogging => dotenv.get(_enableLogging, fallback: 'true') == 'true';
  bool get enableChuckInterceptor => dotenv.get(_enableChuckInterceptor, fallback: 'true') == 'true';

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
}