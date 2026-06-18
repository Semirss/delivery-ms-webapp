import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../logging/app_logger.dart';
import '../monitoring/sentry_service.dart';

abstract class BaseState extends Equatable {
  const BaseState();
}

abstract class BaseEvent extends Equatable {
  const BaseEvent();
}

abstract class BaseBloc<Event extends BaseEvent, State extends BaseState>
    extends Bloc<Event, State> {
  final AppLogger logger;
  final SentryService sentryService;

  BaseBloc({
    required this.logger,
    required this.sentryService,
    required State initialState,
  }) : super(initialState) {
    on<Event>((event, emit) async {
      try {
        logger.debug('Event: ${event.runtimeType}');
        sentryService.addBreadcrumb(
          'Bloc Event: ${event.runtimeType}',
          category: 'bloc',
        );
        await handleEvent(event, emit);
      } catch (error, stackTrace) {
        logger.error('Bloc error in ${runtimeType}', error, stackTrace);
        sentryService.captureException(
          error,
          stackTrace: stackTrace,
          tag: 'bloc_error',
        );
        await handleError(error, stackTrace, emit);
      }
    });
  }

  Future<void> handleEvent(Event event, Emitter<State> emit);

  Future<void> handleError(
    dynamic error,
    StackTrace stackTrace,
    Emitter<State> emit,
  ) async {
    // Override in child classes for custom error handling
  }
}