/// Russian plural forms: 1 ночь, 2 ночи, 5 ночей, 21 ночь, 11 ночей.
abstract final class Plural {
  /// Returns the word form that agrees with [count].
  static String select(
    int count, {
    required String one,
    required String few,
    required String many,
  }) {
    final int value = count.abs();
    final int lastTwoDigits = value % 100;
    if (lastTwoDigits >= 11 && lastTwoDigits <= 14) {
      return many;
    }
    return switch (value % 10) {
      1 => one,
      2 || 3 || 4 => few,
      _ => many,
    };
  }

  /// Returns the count followed by the agreeing form, e.g. `3 ночи`.
  static String format(
    int count, {
    required String one,
    required String few,
    required String many,
  }) {
    return '$count ${select(count, one: one, few: few, many: many)}';
  }
}
