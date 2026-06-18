// ignore_for_file: unawaited_futures, unnecessary_breaks

import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:driver_app/core/databases/api/dio_client.dart';
import 'package:driver_app/core/databases/api/network_exceptions.dart';
import 'package:driver_app/core/utils/enums/data_enums.dart';
import 'package:driver_app/core/utils/functions/base_functions/data_functions.dart';
import 'package:http_parser/http_parser.dart';
import 'package:driver_app/core/databases/api/api_consumer.dart';
import 'package:injectable/injectable.dart';

@Injectable(as: ApiConsumer)
class ApiClient implements ApiConsumer {
  final DioClient dioClient;
  final Dio dio;
  final Connectivity connectivity;
  Map<String, dynamic> defaultParams = {};

  ApiClient({
    required this.dioClient,
    required this.dio,
    required this.connectivity,
  });
  Future<dynamic> request({
    required RequestType requestType,
    bool requiresAuth = true,
    bool requiresDefaultParams = true,
    required String path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    bool showErrorToast = true,
    Map<String, dynamic>? headers,
    bool isResponseStream = false,
    // when set to true, the response type will be of type Map<String, dynamic>,
    // which is the default type. Disable this to return the data
    bool getDataAsRawValue = true,
  }) async {
    try {
      // print calling method
      if (requiresAuth) await dioClient.addAuthorizationInterceptor();
      if (requiresDefaultParams && data != null) {
        //force data to Map<String, dynamic>
        data = Map<String, dynamic>.from(data);
        data.addAll(defaultParams);
      }
      outlog(
        'request :$requestType, \npath: $path, \nqueryParameters: $queryParameters, \ndata: $data, \nheaders: ${dio.options.headers} \n baseUrl: ${dio.options.baseUrl}',
      );
      Options? options;
      if (isResponseStream) {
        options = Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream; application/zip'},
        );
      }
      if (headers != null) {
        options = Options(headers: headers);
      }
      dynamic response;
      switch (requestType) {
        case RequestType.get:
          response = await dioClient.get(
            path,
            options: options,
            queryParameters: queryParameters,
          );
          outlog('response: $response');
          break;
        case RequestType.post:
          response = await dioClient.post(path, options: options, data: data);
          break;
        case RequestType.patch:
          response = await dioClient.patch(path, options: options, data: data);
          break;
        case RequestType.delete:
          response = await dioClient.delete(path, options: options, data: data);
          break;
        case RequestType.put:
          response = await dioClient.put(path, options: options, data: data);
          break;
        case RequestType.stream:
          response = await dioClient.get(path, options: options, data: data);
          break;
      }

      if (isResponseStream) {
        outlog('event initial $response');
        return (response as ResponseBody).stream
            .transform(unit8Transformer)
            .transform(const Utf8Decoder())
            .transform(const LineSplitter());
      }

      outlog('raw response: $response');
      return response;
    } on DioException catch (e) {
      final errorMessage = NetworkExceptions.getErrorMessage(
        NetworkExceptions.getDioException(e),
      );
      outlog('Api Error: $errorMessage');
      outlog('Api Response Data:${e.response?.data}');
      // if (showErrorToast && e.response?.data?['detail'] != null) {
      //   toast("Error", e.response?.data?['detail'], type: ToastTypes.error);
      // }
      if (showErrorToast) {
        // final message = e.response?.data?['message'] ??
        //     e.response?.data?['error'] ??
        //     e.response?.statusMessage;
        final returnedMessage =
            e.response?.data?['statusMessage'] ??
            e.response?.data?['message'] ??
            e.response?.data?['error'] ??
            e.response?.statusMessage ??
            'An error occurred';
        final statusCode = e.response?.statusCode;

        // Toast notifications require BuildContext - log errors instead
        // Users can implement toast notifications in their UI layer
        outlog("API Error: ${statusCode ?? 'Unknown'} - $returnedMessage");
      }
      if (e.response?.data.toString().isNotEmpty ?? false) {}
      return Future.error(errorMessage);
    } catch (e) {
      outlog('error from request $e');
    }
  }

  // sends form data for single or multiple files
  Future<dynamic> sendFile({
    required String path,
    Map<String, String>? files,
    List<String>? pages,
    MediaType? contentType,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await dioClient.uploadFiles(
        path,
        text: fields,
        files: files,
        pages: pages,
        contentType: contentType,
        headers: headers,
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      outlog(e);
      final errorMessage = NetworkExceptions.getErrorMessage(
        NetworkExceptions.getDioException(e),
      );

      outlog('Api Error: $errorMessage');
      outlog('Api Response Data:${e.response}');
      if (e.response?.data?['message'] != null) {
        outlog("API Error: ${e.response?.data?['message']}");
      }
      if (e.response?.data.toString().isNotEmpty ?? false) {}
      return Future.error(errorMessage);
    }
  }

  void updateUrl(String url) {
    dioClient.updateUrl(url);
  }

  void resetUrl() {
    dioClient.resetUrl();
  }

  // ApiConsumer interface implementation
  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) {
    return request(
      requestType: RequestType.get,
      path: path,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return request(
      requestType: RequestType.post,
      path: path,
      data: data as Map<String, dynamic>?,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return request(
      requestType: RequestType.put,
      path: path,
      data: data as Map<String, dynamic>?,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return request(
      requestType: RequestType.patch,
      path: path,
      data: data as Map<String, dynamic>?,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return request(
      requestType: RequestType.delete,
      path: path,
      data: data as Map<String, dynamic>?,
      queryParameters: queryParameters,
    );
  }
}
