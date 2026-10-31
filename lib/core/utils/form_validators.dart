import 'package:easy_booking/core/utils/validators.dart';

/// `FormField.validator` functions with the messages shown under a field.
///
/// They wrap [Validators], which use cases share, so a form and its use case
/// apply the same rule.
abstract final class FormValidators {
  static const String requiredMessage = 'Заполните поле';
  static const String invalidEmailMessage = 'Проверьте адрес почты';
  static const String invalidPhoneMessage = 'Проверьте номер телефона';
  static const String incompleteOtpMessage = 'Введите код полностью';

  static String? required(String? value) {
    return Validators.isNotBlank(value) ? null : requiredMessage;
  }

  static String? email(String? value) {
    if (value == null || !Validators.isNotBlank(value)) {
      return requiredMessage;
    }
    return Validators.isValidEmail(value) ? null : invalidEmailMessage;
  }

  static String? phone(String? value) {
    return value != null && Validators.isValidPhone(value)
        ? null
        : invalidPhoneMessage;
  }

  static String? otp(String? value) {
    return value != null && Validators.isValidOtp(value)
        ? null
        : incompleteOtpMessage;
  }

  /// For pickers: a value must be chosen.
  static String? selected(Object? value) {
    return value == null ? requiredMessage : null;
  }
}
