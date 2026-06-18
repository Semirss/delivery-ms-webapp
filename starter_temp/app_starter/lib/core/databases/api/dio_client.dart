// ignore_for_file: unawaited_futures

import 'dart:io';

import 'package:chuck_interceptor/chuck_interceptor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:app_starter/core/config/app_config.dart';
import 'package:app_starter/core/databases/api/dio_interceptors.dart';
import 'package:app_starter/core/monitoring/sentry_service.dart';
import 'package:app_starter/core/utils/functions/base_functions/data_functions.dart';
import 'package:http_parser/http_parser.dart';
import 'package:injectable/injectable.dart';

@singleton
class DioClient {
  late Dio _dio;
  final AppConfig _appConfig;
  final SentryService _sentryService;
  final Connectivity connectivity;
  final Chuck _chuck;

  DioClient(
    this._appConfig,
    this._sentryService,
    this.connectivity,
    this._chuck,
  ) {
    _dio = Dio();
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () =>
          HttpClient()
            ..badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
    }

    _dio
      ..options = BaseOptions(
        baseUrl: _appConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: _appConfig.apiTimeout),
        receiveTimeout: Duration(milliseconds: _appConfig.apiTimeout),
        followRedirects: false,
      )
      ..httpClientAdapter
      ..options.headers = {'Content-Type': 'application/json; charset=UTF-8'};

    // Add Sentry interceptor for error tracking
    // Note: Sentry interceptor should be configured via SentryFlutter
    // _dio.interceptors.add(SentryDioInterceptor());

    // Add connectivity retry interceptor
    _dio.interceptors.add(RetryInterceptor(_dio, _sentryService));

    // Add Chuck interceptor for debugging
    if (_appConfig.enableChuckInterceptor && kDebugMode) {
      _dio.interceptors.add(_chuck.dioInterceptor);
    }
  }

  Future<void> addAuthorizationInterceptor() async {
    final hasAuthInterceptor = _dio.interceptors.any(
      (element) => element is AuthorizationInterceptor,
    );
    if (!hasAuthInterceptor) {
      // AuthorizationInterceptor needs to be injected, placeholder for now
      // _dio.interceptors.add(AuthorizationInterceptor(_dio, _storageService, _sentryService));
    }
  }

  Future<void> addAPIkeyInterceptor(String key) async {
    if (key.isNotEmpty) {
      // Add api interceptor if not already added
      final hasApiKeyInterceptor = _dio.interceptors.any(
        (element) => element is APIKeyInterceptor,
      );
      if (!hasApiKeyInterceptor) {
        _dio.interceptors.add(APIKeyInterceptor(_dio, key));
      }
    } else {
      // Remove authorization interceptor if present
      _dio.interceptors.removeWhere((element) => element is APIKeyInterceptor);
    }
  }

  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    dynamic data,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        uri,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        data: data,
      );
      outlog(' ${response.data}');
      return response.data;
    } on SocketException catch (e) {
      throw SocketException(e.toString());
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool getFullResponse = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return getFullResponse ? response : response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    bool getFullResponse = false,
  }) async {
    try {
      final response = await _dio.patch<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return getFullResponse ? response : response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> head(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool getFullResponse = false,
  }) async {
    try {
      final response = await _dio.head<dynamic>(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return getFullResponse ? response : response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> uploadFiles(
    String uri, {
    Map<String, dynamic>? text,
    Map<String, String>? files,
    List<String>? pages,
    MediaType? contentType,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final FormData formData = FormData();
      if (text != null) {
        formData.fields.addAll(
          text.entries.map((e) => MapEntry(e.key, e.value.toString())),
        );
      }

      files?.forEach((key, value) {
        formData.files.add(
          MapEntry(
            key,
            MultipartFile.fromFileSync(value, contentType: contentType),
          ),
        );
      });
      pages?.forEach((element) {
        formData.files.add(
          MapEntry(
            'pages',
            MultipartFile.fromFileSync(
              element,
              contentType: MediaType('application', 'pdf'),
            ),
          ),
        );
      });
      headers?.addAll({
        'accept': 'application/json',
        'content-Type': 'multipart/form-data',
      });
      outlog('headers: $headers');
      outlog('Form data field: ${formData.fields}');
      outlog('Form data files: ${formData.files}');
      outlog('uri: $uri');
      await addAuthorizationInterceptor();
      final response = await _dio.post<dynamic>(
        uri,
        data: formData,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
      );
      outlog('raw response: ${response.data}');
      return response.data;
    } on FormatException catch (_) {
      throw const FormatException('unable_to_process_the_data');
    } catch (e) {
      rethrow;
    }
  }

  void updateUrl(String url) {
    _dio.options.baseUrl = url;
  }

  void resetUrl() {
    _dio.options.baseUrl = _appConfig.apiBaseUrl;
  }
}
