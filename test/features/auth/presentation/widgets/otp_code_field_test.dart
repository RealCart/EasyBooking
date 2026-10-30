import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/features/auth/presentation/widgets/otp_code_field.dart';

/// Hosts an [OtpCodeField] whose `code` follows its own changes, as the
/// BLoC does, and records every reported value.
final class _Host extends StatefulWidget {
  const _Host({required this.changes, this.errorText, this.readOnly = false});

  final List<String> changes;
  final String? errorText;
  final bool readOnly;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  String code = '';

  void setCode(String value) => setState(() => code = value);

  @override
  Widget build(BuildContext context) {
    return OtpCodeField(
      code: code,
      errorText: widget.errorText,
      readOnly: widget.readOnly,
      onChanged: (String value) {
        widget.changes.add(value);
        setCode(value);
      },
    );
  }
}

Future<List<String>> _pump(
  WidgetTester tester, {
  String? errorText,
  bool readOnly = false,
}) async {
  final List<String> changes = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _Host(
            changes: changes,
            errorText: errorText,
            readOnly: readOnly,
          ),
        ),
      ),
    ),
  );
  return changes;
}

Finder get _input => find.byType(TextField);

String _text(WidgetTester tester) {
  return tester.widget<TextField>(_input).controller!.text;
}

void _expectBoxes(String digits) {
  for (int index = 0; index < digits.length; index++) {
    expect(find.text(digits[index]), findsOneWidget, reason: '$index');
  }
}

void main() {
  testWidgets('uses one numeric field with one-time-code autofill', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final TextField field = tester.widget<TextField>(_input);
    expect(_input, findsOneWidget);
    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, <String>[AutofillHints.oneTimeCode]);
  });

  testWidgets('typed digits appear in the boxes', (WidgetTester tester) async {
    final List<String> changes = await _pump(tester);

    await tester.enterText(_input, '482');
    await tester.pump();

    expect(changes, <String>['482']);
    _expectBoxes('482');
  });

  testWidgets('a pasted code fills all six boxes', (
    WidgetTester tester,
  ) async {
    final List<String> changes = await _pump(tester);

    await tester.enterText(_input, '482913');
    await tester.pump();

    expect(changes, <String>['482913']);
    _expectBoxes('482913');
  });

  testWidgets('an autofilled SMS keeps only its digits', (
    WidgetTester tester,
  ) async {
    final List<String> changes = await _pump(tester);
    await tester.showKeyboard(_input);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Код: 48-29 13',
        selection: TextSelection.collapsed(offset: 13),
      ),
    );
    await tester.pump();

    expect(changes, <String>['482913']);
    expect(_text(tester), '482913');
  });

  testWidgets('non-digits are ignored', (WidgetTester tester) async {
    final List<String> changes = await _pump(tester);

    await tester.enterText(_input, '1a2b');
    await tester.pump();

    expect(changes, <String>['12']);
    expect(_text(tester), '12');
  });

  testWidgets('accepts at most six digits', (WidgetTester tester) async {
    final List<String> changes = await _pump(tester);

    await tester.enterText(_input, '12345678');
    await tester.pump();

    expect(changes.last, '123456');
    expect(_text(tester), '123456');
    expect(find.text('7'), findsNothing);
  });

  testWidgets('a code cleared from outside empties the field', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    await tester.enterText(_input, '123456');
    await tester.pump();

    tester.state<_HostState>(find.byType(_Host)).setCode('');
    await tester.pump();

    expect(_text(tester), isEmpty);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('shows the error text', (WidgetTester tester) async {
    await _pump(tester, errorText: 'Неверный код');

    expect(find.text('Неверный код'), findsOneWidget);
  });

  testWidgets('read-only ignores input', (WidgetTester tester) async {
    final List<String> changes = await _pump(tester, readOnly: true);

    expect(tester.widget<TextField>(_input).readOnly, isTrue);
    await tester.enterText(_input, '123');
    await tester.pump();

    expect(changes, isEmpty);
  });
}
