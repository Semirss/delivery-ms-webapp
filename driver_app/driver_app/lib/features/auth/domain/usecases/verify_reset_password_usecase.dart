import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyResetPasswordUseCase implements UseCase<void, VerifyResetPasswordParams> {
  final AuthRepository repository;

  VerifyResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyResetPasswordParams params) async {
    return await repository.verifyResetPassword(params);
  }
}

