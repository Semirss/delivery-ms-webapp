import 'package:flutter/foundation.dart';
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

  static const String _environmentDefine = String.fromEnvironment(
    _environment,
  );
  static const String _appNameDefine = String.fromEnvironment(_appName);
  static const String _apiBaseUrlDefine = String.fromEnvironment(_apiBaseUrl);
  static const String _apiTimeoutDefine = String.fromEnvironment(_apiTimeout);
  static const String _sentryDsnDefine = String.fromEnvironment(_sentryDsn);
  static const String _sentryEnvironmentDefine = String.fromEnvironment(
    _sentryEnvironment,
  );
  static const String _enableLoggingDefine = String.fromEnvironment(
    _enableLogging,
  );
  static const String _enableChuckInterceptorDefine = String.fromEnvironment(
    _enableChuckInterceptor,
  );

  String get environment => _env(
    _environment,
    fallback: _environmentDefine.isNotEmpty ? _environmentDefine : 'production',
  );
  String get appName => _env(
    _appName,
    fallback: _appNameDefine.isNotEmpty ? _appNameDefine : 'MotoBike',
  );
  String get apiBaseUrl => _env(_apiBaseUrl, fallback: _apiBaseUrlDefine);
  int get apiTimeout {
    final value = _env(
      _apiTimeout,
      fallback: _apiTimeoutDefine.isNotEmpty ? _apiTimeoutDefine : '30000',
    );
    return int.tryParse(value) ?? 30000;
  }

  String get sentryDsn => _env(_sentryDsn, fallback: _sentryDsnDefine);
  String get sentryEnvironment => _env(
    _sentryEnvironment,
    fallback: _sentryEnvironmentDefine.isNotEmpty
        ? _sentryEnvironmentDefine
        : environment,
  );
  bool get enableLogging => _boolEnv(
    _enableLogging,
    fallback: _enableLoggingDefine.isNotEmpty ? _enableLoggingDefine : 'false',
  );
  bool get enableChuckInterceptor => _boolEnv(
    _enableChuckInterceptor,
    fallback: _enableChuckInterceptorDefine.isNotEmpty
        ? _enableChuckInterceptorDefine
        : kIsWeb
            ? 'false'
            : 'true',
  );

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  String _env(String key, {required String fallback}) {
    try {
      return dotenv.get(key, fallback: fallback).trim();
    } catch (_) {
      return fallback.trim();
    }
  }

  bool _boolEnv(String key, {required String fallback}) {
    return _env(key, fallback: fallback).toLowerCase() == 'true';
  }
}
