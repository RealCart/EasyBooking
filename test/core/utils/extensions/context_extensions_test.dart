import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';
import 'package:easy_booking/core/widgets/feedback/app_snackbar.dart';

final class _Host extends StatelessWidget {
  const _Host({required this.onPressed});

  final void Function(BuildContext context) onPressed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return Column(
              children: <Widget>[
                const TextField(key: Key('field')),
                TextButton(
                  onPressed: () => onPressed(context),
                  child: const Text('Trigger'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() {
  group('ContextExtensions.showAppSnackbar', () {
    testWidgets('shows an AppSnackbar with the message and action', (
      WidgetTester tester,
    ) async {
      int actionCount = 0;
      await tester.pumpWidget(
        _Host(
          onPressed: (BuildContext context) => context.showAppSnackbar(
            'Сохранено',
            actionLabel: 'Отменить',
            onAction: () => actionCount++,
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSnackbar), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);

      await tester.tap(find.text('Отменить'));
      await tester.pump();

      expect(actionCount, 1);
    });

    testWidgets('replaces the visible snackbar instead of queueing', (
      WidgetTester tester,
    ) async {
      int calls = 0;
      await tester.pumpWidget(
        _Host(
          onPressed: (BuildContext context) {
            calls++;
            context.showAppSnackbar('Сообщение $calls');
          },
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Сообщение 1'), findsNothing);
      expect(find.text('Сообщение 2'), findsOneWidget);
      expect(find.byType(AppSnackbar), findsOneWidget);
    });
  });

  group('ContextExtensions.hideKeyboard', () {
    testWidgets('removes focus from the focused field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _Host(onPressed: (BuildContext context) => context.hideKeyboard()),
      );
      await tester.showKeyboard(find.byKey(const Key('field')));
      final EditableTextState editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.widget.focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Trigger'));
      await tester.pump();

      expect(editable.widget.focusNode.hasFocus, isFalse);
    });
  });
}
