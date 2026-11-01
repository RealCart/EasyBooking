import 'package:easy_booking/core/utils/error/field_error_codes.dart';

/// Error codes of the contracts feature, used in `ValidationFailure.code`
/// and as `ValidationFailure.fieldErrors` values.
///
/// Codes shared with other features alias [FieldErrorCodes].
abstract final class ContractErrorCodes {
  // Codes.
  /// The contract is signed and can no longer change or be sent.
  static const String alreadySigned = 'contract_signed';
  static const String invalidPhone = FieldErrorCodes.invalidPhone;
  static const String invalidEmail = FieldErrorCodes.invalidEmail;

  // Field codes.
  static const String required = FieldErrorCodes.required;
  static const String invalidIin = 'invalid_iin';
  static const String invalidIdNumber = 'invalid_id_number';
}
