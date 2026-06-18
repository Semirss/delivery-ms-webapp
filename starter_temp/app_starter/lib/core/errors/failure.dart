class Failure {
  final String errMessage;
  Failure({required this.errMessage});
}

class ServerFailure extends Failure {
  ServerFailure(String message) : super(errMessage: message);
}

class CacheFailure extends Failure {
  CacheFailure(String message) : super(errMessage: message);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message) : super(errMessage: message);
}
