/// Field error codes shared by several features, used as
/// `ValidationFailure.fieldErrors` values by the use cases and the server.
///
/// Feature-only codes stay in the feature's `<feature>_error_codes.dart`.
abstract final class FieldErrorCodes {
  static const String required = 'required';
  static const String invalidEmail = 'invalid_email';
  static const String invalidPhone = 'invalid_phone';
}
