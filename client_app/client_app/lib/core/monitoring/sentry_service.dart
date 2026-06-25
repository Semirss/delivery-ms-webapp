import 'package:flutter/foundation.dart';
import 'package:client_app/core/config/app_config.dart';
import 'package:injectable/injectable.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

@singleton
class SentryService {
  SentryService(this._appConfig);
  final AppConfig _appConfig;

  Future<void> initialize() async {
    final dsn = _appConfig.sentryDsn.trim();
    if (!_isValidDsn(dsn)) {
      if (kDebugMode && dsn.isNotEmpty) {
        debugPrint('Sentry disabled: invalid SENTRY_DSN "$dsn"');
      }
      return;
    }

    try {
      await SentryFlutter.init(
        (options) {
          options
            ..dsn = dsn
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sentry disabled: failed to initialize: $e');
      }
    }
  }

  bool _isValidDsn(String dsn) {
    if (dsn.isEmpty) return false;
    final lower = dsn.toLowerCase();
    if (lower.contains('your_') ||
        lower.contains('placeholder') ||
        lower.contains('example')) {
      return false;
    }

    final uri = Uri.tryParse(dsn);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
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

  void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
  }) {
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
