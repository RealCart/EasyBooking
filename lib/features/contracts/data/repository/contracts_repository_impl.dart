import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/data/sources/local/contracts_mock_local.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';

/// Delegates to [ContractsMockLocal], which already returns entities and
/// holds the contracts in memory as their source of truth.
final class ContractsRepositoryImpl implements ContractsRepository {
  const ContractsRepositoryImpl({required this._local});

  final ContractsMockLocal _local;

  @override
  Future<Either<Failure, ContractEntity>> getContract(String id) {
    return _local.loadContract(id);
  }

  @override
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  ) {
    return _local.updateGuest(params);
  }

  @override
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  ) {
    return _local.sendContract(params);
  }
}
