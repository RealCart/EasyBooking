import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

final class SignOutUsecase
    implements Usecase<Future<Either<Failure, void>>, NoParams> {
  const SignOutUsecase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) => _repository.signOut();
}
