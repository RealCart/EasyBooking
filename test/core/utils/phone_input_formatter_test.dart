import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/phone_input_formatter.dart';

TextEditingValue _value(String text, [int? caret]) {
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: caret ?? text.length),
  );
}

TextEditingValue _format(TextEditingValue oldValue, TextEditingValue newValue) {
  return const PhoneInputFormatter().formatEditUpdate(oldValue, newValue);
}

void main() {
  group('PhoneInputFormatter.formatEditUpdate', () {
    test('formats typed digits and keeps the caret at the end', () {
      final TextEditingValue result = _format(
        _value('700 123 45 6'),
        _value('700 123 45 67'),
      );

      expect(result.text, '700 123 45 67');
      expect(result.selection, const TextSelection.collapsed(offset: 13));
    });

    test('inserts a group space when a group fills up', () {
      final TextEditingValue result = _format(_value('700'), _value('7001'));

      expect(result.text, '700 1');
      expect(result.selection.baseOffset, 5);
    });

    test('keeps the caret after the same digit when editing the middle', () {
      // Typing "9" after "70" in "700 123".
      final TextEditingValue result = _format(
        _value('700 123', 2),
        _value('7090 123', 3),
      );

      expect(result.text, '709 012 3');
      expect(result.selection.baseOffset, 3);
    });

    test('keeps the caret after the same digit across a new space', () {
      // Typing "5" after "7001" in "700 1".
      final TextEditingValue result = _format(
        _value('700 1', 5),
        _value('700 15', 6),
      );

      expect(result.text, '700 15');
      expect(result.selection.baseOffset, 6);
    });

    test('deleting a digit reformats and keeps the caret in place', () {
      // Backspace after "700 1" in "700 123".
      final TextEditingValue result = _format(
        _value('700 123', 5),
        _value('700 23', 4),
      );

      expect(result.text, '700 23');
      expect(result.selection.baseOffset, 3);
    });

    test('pasting a full +7 number keeps only the national digits', () {
      final TextEditingValue result = _format(
        _value(''),
        _value('+7 700 123 45 67'),
      );

      expect(result.text, '700 123 45 67');
      expect(result.selection.baseOffset, 13);
    });

    test('pasting a full 8 number keeps only the national digits', () {
      final TextEditingValue result = _format(
        _value(''),
        _value('87001234567'),
      );

      expect(result.text, '700 123 45 67');
      expect(result.selection.baseOffset, 13);
    });

    test('an extra digit typed into a full field is ignored', () {
      final TextEditingValue full = _value('700 123 45 67');

      final TextEditingValue result = _format(full, _value('700 123 45 678'));

      expect(result, full);
    });

    test('pasting a full +7 number over a selected full field replaces it', () {
      const TextEditingValue full = TextEditingValue(
        text: '700 123 45 67',
        selection: TextSelection(baseOffset: 0, extentOffset: 13),
      );

      final TextEditingValue result = _format(
        full,
        _value('+7 701 999 88 77'),
      );

      expect(result.text, '701 999 88 77');
      expect(result.selection.baseOffset, 13);
    });

    test('non-digit input is dropped', () {
      final TextEditingValue result = _format(_value('700'), _value('700a'));

      expect(result.text, '700');
      expect(result.selection.baseOffset, 3);
    });
  });

  testWidgets('a TextField with the formatter shows grouped digits', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: TextField(
            controller: controller,
            inputFormatters: const <TextInputFormatter>[PhoneInputFormatter()],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '7001234567');

    expect(controller.text, '700 123 45 67');
  });
}
