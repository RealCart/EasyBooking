import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';

/// Validates and saves the guest data of a contract.
///
/// Names are trimmed; spaces in the IIN and the identity card number are
/// removed. The form validates too, for immediate feedback; this check keeps
/// the rule in the domain for every caller.
final class UpdateContractGuestUsecase
    implements
        Usecase<
          Future<Either<Failure, ContractEntity>>,
          UpdateContractGuestParamsEntity
        > {
  const UpdateContractGuestUsecase(this._repository);

  final ContractsRepository _repository;

  static final RegExp _whitespace = RegExp(r'\s');

  @override
  Future<Either<Failure, ContractEntity>> call(
    UpdateContractGuestParamsEntity params,
  ) async {
    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String patronymic = params.patronymic.trim();
    final String iin = params.iin.replaceAll(_whitespace, '');
    final String idNumber = params.idNumber.replaceAll(_whitespace, '');

    final Map<String, String> fieldErrors = <String, String>{
      if (!Validators.isNotBlank(firstName))
        ContractGuestFields.firstName: ContractErrorCodes.required,
      if (!Validators.isNotBlank(lastName))
        ContractGuestFields.lastName: ContractErrorCodes.required,
      if (iin.isEmpty)
        ContractGuestFields.iin: ContractErrorCodes.required
      else if (!Validators.isValidIin(iin))
        ContractGuestFields.iin: ContractErrorCodes.invalidIin,
      if (idNumber.isEmpty)
        ContractGuestFields.idNumber: ContractErrorCodes.required
      else if (!Validators.isValidIdNumber(idNumber))
        ContractGuestFields.idNumber: ContractErrorCodes.invalidIdNumber,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, ContractEntity>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.updateGuest(
      UpdateContractGuestParamsEntity(
        contractId: params.contractId,
        firstName: firstName,
        lastName: lastName,
        patronymic: patronymic,
        iin: iin,
        idNumber: idNumber,
      ),
    );
  }
}
