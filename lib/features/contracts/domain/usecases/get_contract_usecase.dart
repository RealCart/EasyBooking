import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/get_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';

final class GetContractUsecase
    implements
        Usecase<
          Future<Either<Failure, ContractEntity>>,
          GetContractParamsEntity
        > {
  const GetContractUsecase(this._repository);

  final ContractsRepository _repository;

  @override
  Future<Either<Failure, ContractEntity>> call(GetContractParamsEntity params) {
    return _repository.getContract(params.contractId);
  }
}
