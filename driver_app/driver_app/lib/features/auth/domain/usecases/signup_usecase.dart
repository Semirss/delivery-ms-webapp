import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';
import '../repositories/auth_repository.dart';

@injectable
class SignUpUseCase implements UseCase<AuthResult, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(SignUpParams params) async {
    return await repository.signUp(params);
  }
}

