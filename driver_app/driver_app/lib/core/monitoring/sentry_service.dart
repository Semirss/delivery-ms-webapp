import 'package:flutter/foundation.dart';
import 'package:driver_app/core/config/app_config.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@singleton
class SentryService {

  SentryService(this._appConfig);
  final AppConfig _appConfig;

  Future<void> initialize() async {
    if (_appConfig.sentryDsn.isEmpty) return;

    await SentryFlutter.init(
      (options) {
        options..dsn = _appConfig.sentryDsn
        ..environment = _appConfig.sentryEnvironment
        ..debug = kDebugMode
        ..tracesSampleRate = _appConfig.isDevelopment ? 1.0 : 0.1
        ..beforeSend = (event, hint) {
          if (_appConfig.isDevelopment) {
            debugPrint('Sentry Event: ${event.toString()}');
          }
          return event;
        };
      },
    );
  }

  void captureException(dynamic exception, {dynamic stackTrace, String? tag}) {
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (tag != null) scope.setTag('error_type', tag);
      },
    );
  }

  void captureMessage(String message, {SentryLevel level = SentryLevel.info}) {
    Sentry.captureMessage(message, level: level);
  }

  void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        timestamp: DateTime.now(),
      ),
    );
  }
}