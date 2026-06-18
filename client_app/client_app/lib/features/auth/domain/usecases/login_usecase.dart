import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';
import '../repositories/auth_repository.dart';

@injectable
class LoginUseCase implements UseCase<AuthResult, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(LoginParams params) async {
    return await repository.login(params);
  }
}

