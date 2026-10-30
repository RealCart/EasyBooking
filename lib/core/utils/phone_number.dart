/// Kazakhstan phone numbers (+7, ten national digits).
abstract final class PhoneNumber {
  static const String countryCode = '+7';
  static const int nationalLength = 10;

  /// Extracts the ten national digits from any user input, accepting a
  /// leading `+7`, `7`, or `8`. Returns `null` when the input is not a
  /// complete Kazakhstan number (national numbers start with `7`).
  static String? toNational(String input) {
    final String digits = digitsOnly(input);
    final String national = hasTrunkPrefix(digits)
        ? digits.substring(1)
        : digits;
    if (national.length != nationalLength || !national.startsWith('7')) {
      return null;
    }
    return national;
  }

  /// The national digits typed so far, at most ten. A full number that was
  /// pasted or autofilled with its `+7` or `8` prefix loses that prefix.
  static String nationalDigits(String input) {
    final String digits = digitsOnly(input);
    final String national = hasTrunkPrefix(digits)
        ? digits.substring(1)
        : digits;
    return national.length > nationalLength
        ? national.substring(0, nationalLength)
        : national;
  }

  /// Whether [digits] is a full number written with its `7` or `8` prefix.
  static bool hasTrunkPrefix(String digits) {
    return digits.length == nationalLength + 1 &&
        (digits.startsWith('7') || digits.startsWith('8'));
  }

  /// `+77001234567`, the format to send to the server, or `null` when the
  /// input is not a complete number.
  static String? toE164(String input) {
    final String? national = toNational(input);
    return national == null ? null : '$countryCode$national';
  }

  /// `+7 700 123 45 67`. Returns [input] unchanged when it is not a complete
  /// number, so unknown formats are still displayed.
  static String format(String input) {
    final String? national = toNational(input);
    if (national == null) {
      return input;
    }
    return '$countryCode ${formatNational(national)}';
  }

  /// `700 123 45 67` for the digits typed so far; see [nationalDigits].
  static String formatNational(String input) {
    final String limited = nationalDigits(input);
    const List<int> groupEnds = <int>[3, 6, 8, 10];
    final StringBuffer buffer = StringBuffer();
    int start = 0;
    for (final int end in groupEnds) {
      if (start >= limited.length) {
        break;
      }
      if (start > 0) {
        buffer.write(' ');
      }
      buffer.write(
        limited.substring(start, end < limited.length ? end : limited.length),
      );
      start = end;
    }
    return buffer.toString();
  }

  static String digitsOnly(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }
}
