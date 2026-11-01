import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';

/// Sends the signing link to the guest, first time or again.
///
/// Phone numbers in any user-typed format are sent as E.164; emails are
/// trimmed. An invalid address is a `ValidationFailure` with
/// [ContractErrorCodes.invalidPhone] or [ContractErrorCodes.invalidEmail].
final class SendContractUsecase
    implements
        Usecase<
          Future<Either<Failure, ContractEntity>>,
          SendContractParamsEntity
        > {
  const SendContractUsecase(this._repository);

  final ContractsRepository _repository;

  @override
  Future<Either<Failure, ContractEntity>> call(
    SendContractParamsEntity params,
  ) async {
    final String? address = _normalizedAddress(params);
    if (address == null) {
      return Left<Failure, ContractEntity>(
        ValidationFailure(
          code: params.channel.usesPhone
              ? ContractErrorCodes.invalidPhone
              : ContractErrorCodes.invalidEmail,
        ),
      );
    }
    return _repository.sendContract(
      SendContractParamsEntity(
        contractId: params.contractId,
        channel: params.channel,
        address: address,
      ),
    );
  }

  static String? _normalizedAddress(SendContractParamsEntity params) {
    if (params.channel.usesPhone) {
      return PhoneNumber.toE164(params.address);
    }
    final String email = params.address.trim();
    return Validators.isValidEmail(email) ? email : null;
  }
}
