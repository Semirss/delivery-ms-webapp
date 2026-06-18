import 'package:dartz/dartz.dart';
import '../errors/failure.dart';
import '../logging/app_logger.dart';
import '../monitoring/sentry_service.dart';

abstract class BaseRepository {
  final AppLogger logger;
  final SentryService sentryService;

  BaseRepository({
    required this.logger,
    required this.sentryService,
  });

  Future<Either<Failure, T>> safeCall<T>(
    Future<T> Function() call, {
    String? operation,
  }) async {
    try {
      final result = await call();
      if (operation != null) {
        logger.debug('$operation completed successfully');
      }
      return Right(result);
    } catch (error, stackTrace) {
      final errorMessage = operation != null 
          ? '$operation failed: $error'
          : 'Repository operation failed: $error';
      
      logger.error(errorMessage, error, stackTrace);
      sentryService.captureException(
        error,
        stackTrace: stackTrace,
        tag: 'repository_error',
      );
      
      return Left(_mapErrorToFailure(error));
    }
  }

  Failure _mapErrorToFailure(dynamic error) {
    // Map different types of errors to appropriate failures
    if (error is Exception) {
      return ServerFailure(error.toString());
    }
    return ServerFailure('Unknown error occurred');
  }
}