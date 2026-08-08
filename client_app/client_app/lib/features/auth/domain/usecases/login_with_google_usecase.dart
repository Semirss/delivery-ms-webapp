import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

@injectable
class LoginWithGoogleUseCase implements UseCase<AuthResult, NoParams> {
  final AuthRepository repository;

  LoginWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(NoParams params) async {
    return repository.loginWithGoogle();
  }
}
