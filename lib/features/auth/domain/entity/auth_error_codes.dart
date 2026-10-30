/// Error codes of the auth feature, used in `ValidationFailure.code`,
/// `ServerFailure.code`, and as `ValidationFailure.fieldErrors` values.
abstract final class AuthErrorCodes {
  // API codes.
  static const String invalidPhone = 'invalid_phone';
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String tooManyRequests = 'too_many_requests';

  // Field codes.
  static const String required = 'required';
  static const String invalidEmail = 'invalid_email';
}
