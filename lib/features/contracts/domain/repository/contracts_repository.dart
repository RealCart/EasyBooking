import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';

/// Served by a mock source until the contracts API exists. An unknown
/// contract id is a failure in every method.
abstract interface class ContractsRepository {
  Future<Either<Failure, ContractEntity>> getContract(String id);

  /// Saves validated guest data and returns the updated contract. A signed
  /// contract is a `ValidationFailure`.
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  );

  /// Sends a new signing link to a validated, normalized address and returns
  /// the updated contract. A signed contract is a `ValidationFailure`.
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  );
}
