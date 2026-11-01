import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/guests/domain/entity/create_guest_contract_params_entity.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';

/// Starts a contract draft prefilled with the guest's data and returns its
/// contract id («Создать договор»).
final class CreateGuestContractUsecase
    implements
        Usecase<
          Future<Either<Failure, String>>,
          CreateGuestContractParamsEntity
        > {
  const CreateGuestContractUsecase(this._repository);

  final GuestsRepository _repository;

  @override
  Future<Either<Failure, String>> call(
    CreateGuestContractParamsEntity params,
  ) {
    return _repository.createContract(params.guestId);
  }
}
