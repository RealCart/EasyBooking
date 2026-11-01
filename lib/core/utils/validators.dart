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

  /// A Kazakhstan IIN: 12 digits. Spaces are ignored.
  static bool isValidIin(String value) => _digits(12).hasMatch(_compact(value));

  /// An identity card number: 9 digits. Spaces are ignored.
  static bool isValidIdNumber(String value) {
    return _digits(9).hasMatch(_compact(value));
  }

  /// Whether [value] is within [min] and [max], both inclusive. A missing
  /// bound is not checked.
  static bool isInRange(num value, {num? min, num? max}) {
    return (min == null || value >= min) && (max == null || value <= max);
  }

  static RegExp _digits(int count) => RegExp('^\\d{$count}\$');

  static String _compact(String value) => value.replaceAll(RegExp(r'\s'), '');
}
