import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';

/// An [AppTextField] with a required validator inside a [Form].
final class _Host extends StatefulWidget {
  const _Host({this.errorText});

  final String? errorText;

  @override
  State<_Host> createState() => _HostState();
}

final class _HostState extends State<_Host> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: AppTextField(
        label: 'Имя',
        controller: controller,
        errorText: widget.errorText,
        validator: (String? value) =>
            value == null || value.isEmpty ? 'Заполните поле' : null,
      ),
    );
  }
}

Future<_HostState> _pump(WidgetTester tester, {String? errorText}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: _Host(errorText: errorText),
      ),
    ),
  );
  return tester.state<_HostState>(find.byType(_Host));
}

EditableText _editable(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText));
}

void main() {
  testWidgets('shows no error before validation', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Заполните поле'), findsNothing);
  });

  testWidgets('validate shows the message below the field', (
    WidgetTester tester,
  ) async {
    final _HostState host = await _pump(tester);

    expect(host.formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Заполните поле'), findsOneWidget);
  });

  testWidgets('the error clears once the input becomes valid', (
    WidgetTester tester,
  ) async {
    final _HostState host = await _pump(tester);
    host.formKey.currentState!.validate();
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Айгерим');
    await tester.pump();

    expect(find.text('Заполните поле'), findsNothing);
    expect(host.formKey.currentState!.validate(), isTrue);
  });

  testWidgets('validates the controller text, even when set in code', (
    WidgetTester tester,
  ) async {
    final _HostState host = await _pump(tester);

    host.controller.text = 'Айгерим';

    expect(host.formKey.currentState!.validate(), isTrue);
  });

  testWidgets('the validator message takes precedence over errorText', (
    WidgetTester tester,
  ) async {
    final _HostState host = await _pump(tester, errorText: 'Проверьте поле');
    expect(find.text('Проверьте поле'), findsOneWidget);

    host.formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Заполните поле'), findsOneWidget);
    expect(find.text('Проверьте поле'), findsNothing);
  });

  testWidgets('is a single TextFormField, not wrapped in another FormField', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byWidgetPredicate((Widget w) => w is FormField), findsOne);
  });

  testWidgets('a tap on the label focuses the input', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Имя'));
    await tester.pump();

    expect(_editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('a tap on the box padding focuses the input', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final Rect box = tester.getRect(find.byType(InputDecorator));

    await tester.tapAt(box.bottomLeft + const Offset(4, -4));
    await tester.pump();

    expect(_editable(tester).focusNode.hasFocus, isTrue);
  });

  testWidgets('keeps the 72 px box with the label above the input', (
    WidgetTester tester,
  ) async {
    await _pump(tester);
    final Rect box = tester.getRect(find.byType(InputDecorator));

    expect(box.height, 72);
    expect(
      tester.getTopLeft(find.text('Имя')) - box.topLeft,
      const Offset(16, 12),
    );
    expect(
      tester.getTopLeft(find.byType(EditableText)) - box.topLeft,
      const Offset(16, 32),
    );
  });

  testWidgets('leading and trailing keep their gaps to the input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: AppTextField(
            label: 'Пароль',
            leading: SizedBox(key: Key('leading'), width: 20, height: 20),
            trailing: SizedBox(key: Key('trailing'), width: 20, height: 20),
          ),
        ),
      ),
    );
    final Rect box = tester.getRect(find.byType(InputDecorator));
    final Rect input = tester.getRect(find.byType(EditableText));

    expect(
      tester.getTopLeft(find.byKey(const Key('leading'))).dx - box.left,
      16,
    );
    expect(
      input.left - tester.getTopRight(find.byKey(const Key('leading'))).dx,
      12,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('trailing'))).dx - input.right,
      8,
    );
    expect(
      box.right - tester.getTopRight(find.byKey(const Key('trailing'))).dx,
      16,
    );
    expect(tester.getTopLeft(find.text('Пароль')).dx, input.left);
  });
}
