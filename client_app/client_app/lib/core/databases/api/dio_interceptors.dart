import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:client_app/core/monitoring/sentry_service.dart';
import 'package:client_app/core/storage/storage_adapter.dart';
import 'package:client_app/core/storage/storage_key_constants.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthorizationInterceptor extends InterceptorsWrapper {

  AuthorizationInterceptor(
    this.dio,
    this._storageService,
    this._sentryService, {
    this.maxRefresh = 1,
  });
  final Dio dio;
  final IStorageService _storageService;
  final SentryService _sentryService;
  int maxRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storageService.getData(StorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _sentryService.captureException(e, tag: 'auth_interceptor');
      log('auth intercepter catched: $e');
    }
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.statusCode == 401) {
      dio.interceptors.removeWhere(
        (element) => element is AuthorizationInterceptor,
      );
      return handler.reject(
        DioException(
          response: response,
          error: 'token_expired',
          requestOptions: response.requestOptions,
        ),
      );
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      _sentryService.addBreadcrumb(
        'Unauthorized access - redirecting to login',
        category: 'auth',
      );

      // Clear tokens and redirect to login
      await _storageService.clearData(StorageKeys.accessToken);
      await _storageService.clearData(StorageKeys.refreshToken);

      // Navigate to login - you might want to use a navigation service here
      // NavigationService.navigateToLogin();
    }
    handler.next(err);
  }

  // Future _retry(
  //     RequestOptions requestOptions, ErrorInterceptorHandler handler) async {
  //   final responseCompleter = Completer<Response>();
  //   responseCompleter.complete(dio
  //       .request(
  //     requestOptions.path,
  //     cancelToken: requestOptions.cancelToken,
  //     data: requestOptions.data,
  //     onReceiveProgress: requestOptions.onReceiveProgress,
  //     onSendProgress: requestOptions.onSendProgress,
  //     queryParameters: requestOptions.queryParameters,
  //     options: Options(
  //         method: requestOptions.method, headers: requestOptions.headers),
  //   )
  //       .then((value) {
  //     outlog(
  //       value,
  //     );
  //     return value;
  //   }, onError: (e) => {outlog("e"), handler.reject(e)}));
  //   return responseCompleter.future;
  // }
}

@injectable
class RetryInterceptor extends Interceptor {

  RetryInterceptor(this.dio, this._sentryService, {this.maxRetry = 3});
  int maxRetry;
  final Dio dio;
  final SentryService _sentryService;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      if (maxRetry > 0) {
        _sentryService.addBreadcrumb(
          'Retrying request (${3 - maxRetry + 1}/3)',
          category: 'network',
        );
        maxRetry--;
        return _retry(err.requestOptions, handler);
      } else {
        _sentryService.captureException(
          err,
          tag: 'network_timeout_max_retries',
        );
      }
    }
    return handler.next(err);
  }

  Future<void> _retry(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
  ) {
    return dio
        .request<dynamic>(
          requestOptions.path,
          cancelToken: requestOptions.cancelToken,
          data: requestOptions.data,
          onReceiveProgress: requestOptions.onReceiveProgress,
          onSendProgress: requestOptions.onSendProgress,
          queryParameters: requestOptions.queryParameters,
          options: Options(method: requestOptions.method),
        )
        .then(
          (value) => handler.resolve(value),
          onError: (Object e) => handler.reject(
            e is DioException
                ? e
                : DioException(requestOptions: requestOptions, error: e),
          ),
        );
  }
}

@injectable
class APIKeyInterceptor extends InterceptorsWrapper {

  APIKeyInterceptor(this.dio, this.apiKey);
  final String apiKey;
  final Dio dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['x-api-key'] = apiKey;
    return handler.next(options);
  }
}
