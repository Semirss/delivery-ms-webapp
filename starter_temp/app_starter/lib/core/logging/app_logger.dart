import 'package:app_starter/core/config/app_config.dart';
import 'package:app_starter/core/monitoring/sentry_service.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@singleton
class AppLogger {

  AppLogger(this._appConfig, this._sentryService) {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
      level: _appConfig.isDevelopment ? Level.debug : Level.info,
    );
  }
  late Logger _logger;
  final AppConfig _appConfig;
  final SentryService _sentryService;

  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_appConfig.enableLogging) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_appConfig.enableLogging) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
    _sentryService.addBreadcrumb(message, category: 'info');
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_appConfig.enableLogging) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
    _sentryService.addBreadcrumb(message, category: 'warning');
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_appConfig.enableLogging) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
    _sentryService.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      tag: 'app_error',
    );
  }

  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_appConfig.enableLogging) {
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
    _sentryService.captureException(
      error ?? Exception(message),
      stackTrace: stackTrace,
      tag: 'fatal_error',
    );
  }
}