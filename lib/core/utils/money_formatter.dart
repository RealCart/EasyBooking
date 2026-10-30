abstract final class MoneyFormatter {
  // A no-break space keeps the amount and the currency on one line.
  static const String _groupSeparator = ' ';
  static const String _tengeSign = '₸';

  /// `42 500 ₸`. [amount] is in whole tenge.
  static String tenge(int amount) {
    return '${group(amount)}$_groupSeparator$_tengeSign';
  }

  /// `42 500 ₸ / ночь`, which never wraps before the slash.
  static String tengePerNight(int amount) {
    return '${tenge(amount)}$_groupSeparator/ ночь';
  }

  /// `1 250 000`: digits grouped by three.
  static String group(int amount) {
    final String digits = amount.abs().toString();
    final StringBuffer buffer = StringBuffer(amount < 0 ? '−' : '');
    for (int index = 0; index < digits.length; index++) {
      final int remaining = digits.length - index;
      if (index > 0 && remaining % 3 == 0) {
        buffer.write(_groupSeparator);
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
