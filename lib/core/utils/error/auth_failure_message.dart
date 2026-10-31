import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';

extension AuthFailureMessage on Failure {
  /// Text for an auth failure. Known API codes get their own message;
  /// anything else falls back to the shared [userMessage].
  String get authMessage {
    const String tooManyRequests = 'Слишком много попыток. Попробуйте позже';
    if (this case ServerFailure(statusCode: 429)) {
      return tooManyRequests;
    }
    // Auth requests run before sign-in, so a 401 means the code or the
    // challenge was rejected, not that a session expired.
    if (this is UnauthorizedFailure) {
      return 'Не удалось войти. Запросите код ещё раз';
    }
    final String? code = switch (this) {
      ValidationFailure(:final String? code) => code,
      ServerFailure(:final String? code) => code,
      _ => null,
    };
    return switch (code) {
      AuthErrorCodes.invalidPhone => FormValidators.invalidPhoneMessage,
      AuthErrorCodes.invalidCode => 'Неверный код',
      AuthErrorCodes.codeExpired => 'Код истёк. Запросите новый',
      AuthErrorCodes.tooManyRequests => tooManyRequests,
      _ => userMessage,
    };
  }
}

/// Text for an `AccountSetupState.fieldErrors` value, or `null` when the
/// field has no error. Server texts are not shown as is because their
/// wording is not controlled by the app.
String? authFieldErrorMessage(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  return switch (code) {
    AuthErrorCodes.required => FormValidators.requiredMessage,
    AuthErrorCodes.invalidEmail => FormValidators.invalidEmailMessage,
    _ => 'Проверьте поле',
  };
}
