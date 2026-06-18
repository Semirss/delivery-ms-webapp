import 'package:dio/dio.dart';
import 'error_model.dart';
//!ServerException
class ServerException implements Exception {
  final ErrorModel errorModel;
  ServerException(this.errorModel);
}
//!CacheExeption
class CacheExeption implements Exception {
  final String errorMessage;
  CacheExeption({required this.errorMessage});
}

class BadCertificateException extends ServerException {
  BadCertificateException(super.errorModel);
}

class ConnectionTimeoutException extends ServerException {
  ConnectionTimeoutException(super.errorModel);
}

class BadResponseException extends ServerException {
  BadResponseException(super.errorModel);
}

class ReceiveTimeoutException extends ServerException {
  ReceiveTimeoutException(super.errorModel);
}

class ConnectionErrorException extends ServerException {
  ConnectionErrorException(super.errorModel);
}

class SendTimeoutException extends ServerException {
  SendTimeoutException(super.errorModel);
}

class UnauthorizedException extends ServerException {
  UnauthorizedException(super.errorModel);
}

class ForbiddenException extends ServerException {
  ForbiddenException(super.errorModel);
}

class NotFoundException extends ServerException {
  NotFoundException(super.errorModel);
}

class CofficientException extends ServerException {
  CofficientException(super.errorModel);
}

class CancelException extends ServerException {
  CancelException(super.errorModel);
}

class UnknownException extends ServerException {
  UnknownException(super.errorModel);
}

Never handleDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
      final data = e.response?.data;
      throw ConnectionErrorException(
        data is Map<String, dynamic> 
          ? ErrorModel.fromJson(data)
          : ErrorModel(status: 500, errorMessage: 'Connection error')
      );
    case DioExceptionType.badCertificate:
      final data = e.response?.data;
      throw BadCertificateException(
        data is Map<String, dynamic>
          ? ErrorModel.fromJson(data)
          : ErrorModel(status: 500, errorMessage: 'Bad certificate')
      );
    case DioExceptionType.connectionTimeout:
      final data = e.response?.data;
      throw ConnectionTimeoutException(
        data is Map<String, dynamic>
          ? ErrorModel.fromJson(data)
          : ErrorModel(status: 408, errorMessage: 'Connection timeout')
      );

    case DioExceptionType.receiveTimeout:
      final data = e.response?.data;
      throw ReceiveTimeoutException(
        data is Map<String, dynamic>
          ? ErrorModel.fromJson(data)
          : ErrorModel(status: 408, errorMessage: 'Receive timeout')
      );

    case DioExceptionType.sendTimeout:
      final data = e.response?.data;
      throw SendTimeoutException(
        data is Map<String, dynamic>
          ? ErrorModel.fromJson(data)
          : ErrorModel(status: 408, errorMessage: 'Send timeout')
      );

    case DioExceptionType.badResponse:
      switch (e.response?.statusCode) {
        case 400: // Bad request
          final data = e.response!.data;
          throw BadResponseException(
            data is Map<String, dynamic>
              ? ErrorModel.fromJson(data)
              : ErrorModel(status: 400, errorMessage: 'Bad request')
          );

        case 401: //unauthorized
          final data = e.response!.data;
          throw UnauthorizedException(
            data is Map<String, dynamic>
              ? ErrorModel.fromJson(data)
              : ErrorModel(status: 401, errorMessage: 'Unauthorized')
          );

        case 403: //forbidden
          final data = e.response!.data;
          throw ForbiddenException(
            data is Map<String, dynamic>
              ? ErrorModel.fromJson(data)
              : ErrorModel(status: 403, errorMessage: 'Forbidden')
          );

        case 404: //not found
          final data = e.response!.data;
          throw NotFoundException(
            data is Map<String, dynamic>
              ? ErrorModel.fromJson(data)
              : ErrorModel(status: 404, errorMessage: 'Not found')
          );

        case 409: //cofficient
          final data = e.response!.data;
          throw CofficientException(
            data is Map<String, dynamic>
              ? ErrorModel.fromJson(data)
              : ErrorModel(status: 409, errorMessage: 'Conflict')
          );

        case 504: // Bad request
          throw BadResponseException(
            ErrorModel(
              status: 504, 
              errorMessage: e.response!.data is String 
                ? e.response!.data as String
                : 'Gateway timeout'
            )
          );
      }
      break;

    case DioExceptionType.cancel:
      throw CancelException(
        ErrorModel(errorMessage: e.toString(), status: 500)
      );

    case DioExceptionType.unknown:
      throw UnknownException(
          ErrorModel(errorMessage: e.toString(), status: 500));
  }
  // This should never be reached due to exhaustive switch
  throw UnknownException(ErrorModel(errorMessage: 'Unknown error', status: 500));
}
