import 'package:easy_booking/core/utils/money_formatter.dart';
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
  static const String invalidIinMessage = 'Проверьте ИИН';
  static const String invalidIdNumberMessage = 'Проверьте номер удостоверения';
  static const String invalidAmountMessage = 'Проверьте сумму';

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

  static String? iin(String? value) {
    if (!Validators.isNotBlank(value)) {
      return requiredMessage;
    }
    return Validators.isValidIin(value!) ? null : invalidIinMessage;
  }

  static String? idNumber(String? value) {
    if (!Validators.isNotBlank(value)) {
      return requiredMessage;
    }
    return Validators.isValidIdNumber(value!) ? null : invalidIdNumberMessage;
  }

  /// A tenge amount above zero, such as a price.
  static String? positiveAmount(String? value) {
    return _amount(value, min: 1);
  }

  /// A tenge amount of zero or more, such as a deposit.
  static String? nonNegativeAmount(String? value) {
    return _amount(value, min: 0);
  }

  /// A whole number from [min] to [max], such as rooms or minimum nights.
  static String? Function(String?) wholeNumberInRange({
    required int min,
    required int max,
  }) {
    return (String? value) {
      if (!Validators.isNotBlank(value)) {
        return requiredMessage;
      }
      final int? number = int.tryParse(value!.trim());
      return number != null && Validators.isInRange(number, min: min, max: max)
          ? null
          : 'Введите число от $min до $max';
    };
  }

  static String? _amount(String? value, {required int min}) {
    if (!Validators.isNotBlank(value)) {
      return requiredMessage;
    }
    final int? amount = MoneyFormatter.tryParse(value);
    return amount != null && Validators.isInRange(amount, min: min)
        ? null
        : invalidAmountMessage;
  }
}
