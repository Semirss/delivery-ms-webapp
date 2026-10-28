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

  String get environment => _env(_environment);
  String get appName => _env(_appName, fallback: 'MotoBike Driver');
  String get apiBaseUrl => _env(_apiBaseUrl);
  int get apiTimeout => int.tryParse(_env(_apiTimeout)) ?? 30000;
  String get sentryDsn => _env(_sentryDsn);
  String get sentryEnvironment =>
      _env(_sentryEnvironment, fallback: environment);
  bool get enableLogging => _env(_enableLogging) == 'true';
  bool get enableChuckInterceptor => _env(_enableChuckInterceptor) == 'true';

  String _env(String key, {String fallback = ''}) {
    final defined = switch (key) {
      _environment => const String.fromEnvironment('ENVIRONMENT'),
      _appName => const String.fromEnvironment('APP_NAME'),
      _apiBaseUrl => const String.fromEnvironment('API_BASE_URL'),
      _apiTimeout => const String.fromEnvironment('API_TIMEOUT'),
      _sentryDsn => const String.fromEnvironment('SENTRY_DSN'),
      _sentryEnvironment => const String.fromEnvironment('SENTRY_ENVIRONMENT'),
      _enableLogging => const String.fromEnvironment('ENABLE_LOGGING'),
      _enableChuckInterceptor => const String.fromEnvironment(
        'ENABLE_CHUCK_INTERCEPTOR',
      ),
      _ => '',
    };
    return defined.isNotEmpty ? defined.trim() : fallback;
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
}
