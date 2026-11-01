import 'package:easy_booking/core/utils/error/field_error_codes.dart';

/// Error codes of the auth feature, used in `ValidationFailure.code`,
/// `ServerFailure.code`, and as `ValidationFailure.fieldErrors` values.
///
/// Codes shared with other features alias [FieldErrorCodes].
abstract final class AuthErrorCodes {
  // API codes.
  static const String invalidPhone = FieldErrorCodes.invalidPhone;
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String tooManyRequests = 'too_many_requests';

  // Field codes.
  static const String required = FieldErrorCodes.required;
  static const String invalidEmail = FieldErrorCodes.invalidEmail;
}
