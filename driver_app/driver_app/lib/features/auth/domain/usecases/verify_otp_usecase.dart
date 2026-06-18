import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/params/auth_params.dart';
import '../repositories/auth_repository.dart';

@injectable
class VerifyOtpUseCase implements UseCase<AuthResult, OtpVerificationParams> {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResult>> call(OtpVerificationParams params) async {
    return await repository.verifyOtp(params);
  }
}
