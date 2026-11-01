import 'package:easy_booking/core/utils/error/field_error_codes.dart';
import 'package:easy_booking/core/utils/form_validators.dart';

/// Text for a shared [FieldErrorCodes] value, or `null` when the field has no
/// error. Unknown codes get a generic text: server texts are not shown as is
/// because their wording is not controlled by the app.
String? fieldErrorMessage(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  return switch (code) {
    FieldErrorCodes.required => FormValidators.requiredMessage,
    FieldErrorCodes.invalidEmail => FormValidators.invalidEmailMessage,
    FieldErrorCodes.invalidPhone => FormValidators.invalidPhoneMessage,
    _ => 'Проверьте поле',
  };
}
