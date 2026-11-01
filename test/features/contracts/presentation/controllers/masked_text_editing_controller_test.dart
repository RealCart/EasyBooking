import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/features/contracts/presentation/controllers/masked_text_editing_controller.dart';

/// Builds the span that an `EditableText` would draw for [controller].
Future<String> _shown(
  WidgetTester tester,
  MaskedTextEditingController controller, {
  bool withComposing = true,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    Builder(
      builder: (BuildContext builderContext) {
        context = builderContext;
        return const SizedBox();
      },
    ),
  );
  return controller
      .buildTextSpan(context: context, withComposing: withComposing)
      .toPlainText();
}

void main() {
  group('MaskedTextEditingController', () {
    late MaskedTextEditingController controller;

    setUp(() {
      controller = MaskedTextEditingController(visibleTail: 3)
        ..text = '960312300214';
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('masks all but the last characters and keeps the real text', (
      WidgetTester tester,
    ) async {
      expect(controller.isMasked, isTrue);
      expect(await _shown(tester, controller), '•••••••••214');
      expect(controller.text, '960312300214');
    });

    testWidgets('shows the real text when unmasked', (
      WidgetTester tester,
    ) async {
      controller.isMasked = false;

      expect(await _shown(tester, controller), '960312300214');
    });

    testWidgets('shows the real text while an IME composes', (
      WidgetTester tester,
    ) async {
      controller.value = const TextEditingValue(
        text: '960312300214',
        selection: TextSelection.collapsed(offset: 12),
        composing: TextRange(start: 9, end: 12),
      );

      expect(await _shown(tester, controller), '960312300214');
      expect(
        await _shown(tester, controller, withComposing: false),
        '•••••••••214',
      );
    });

    testWidgets('a text not longer than the tail is shown as is', (
      WidgetTester tester,
    ) async {
      controller.text = '21';

      expect(await _shown(tester, controller), '21');
    });

    testWidgets('spaces stay visible so the length is unchanged', (
      WidgetTester tester,
    ) async {
      controller.text = '960 312 300 214';

      final String shown = await _shown(tester, controller);

      expect(shown, '••• ••• ••• 214');
      expect(shown.length, controller.text.length);
    });

    test('toggling notifies once and setting the same value does not', () {
      int notifications = 0;
      void listener() => notifications++;
      controller.addListener(listener);
      addTearDown(() => controller.removeListener(listener));

      controller.isMasked = false;
      controller.isMasked = false;
      controller.isMasked = true;

      expect(notifications, 2);
    });
  });
}
