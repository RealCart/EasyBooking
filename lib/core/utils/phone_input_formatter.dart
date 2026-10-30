import 'package:flutter/services.dart';

import 'package:easy_booking/core/utils/phone_number.dart';

/// Formats the national part of a Kazakhstan number as `700 123 45 67`
/// while typing. The `+7` prefix is shown by the country field.
final class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // A full field ignores one more typed digit; otherwise the 11 digits
    // would look like a number with a `7`/`8` prefix and be shifted. A paste
    // over a selection replaces the number instead.
    final int oldDigits = PhoneNumber.digitsOnly(oldValue.text).length;
    final int newDigits = PhoneNumber.digitsOnly(newValue.text).length;
    if (oldValue.selection.isCollapsed &&
        oldDigits >= PhoneNumber.nationalLength &&
        newDigits == oldDigits + 1) {
      return oldValue;
    }

    final String formatted = PhoneNumber.formatNational(newValue.text);

    // Keep the caret after the same number of digits it was after.
    final int caret = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    // A dropped `+7`/`8` prefix was before the caret, so discount it.
    final int droppedPrefix =
        PhoneNumber.hasTrunkPrefix(PhoneNumber.digitsOnly(newValue.text))
        ? 1
        : 0;
    final int digitsBeforeCaret =
        PhoneNumber.digitsOnly(newValue.text.substring(0, caret)).length -
        droppedPrefix;
    int offset = 0;
    int digitsSeen = 0;
    while (offset < formatted.length && digitsSeen < digitsBeforeCaret) {
      if (formatted.codeUnitAt(offset) != _space) {
        digitsSeen++;
      }
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  static final int _space = ' '.codeUnitAt(0);
}
