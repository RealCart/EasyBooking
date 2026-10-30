import 'package:easy_booking/core/utils/phone_number.dart';

/// Pure input checks shared by use cases and forms.
///
/// They return `bool` so that the caller decides which message to show.
abstract final class Validators {
  static const int otpLength = 6;

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$",
  );

  static bool isNotBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidPhone(String value) {
    return PhoneNumber.toNational(value) != null;
  }

  static bool isValidOtp(String value) {
    return value.length == otpLength &&
        PhoneNumber.digitsOnly(value).length == otpLength;
  }
}
