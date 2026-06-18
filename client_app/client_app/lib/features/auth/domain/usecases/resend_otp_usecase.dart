import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/base/base_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../repositories/auth_repository.dart';

@injectable
class ResendOtpUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  ResendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String verificationKey) async {
    return await repository.resendOtp(verificationKey);
  }
}

