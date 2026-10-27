import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/widgets/actions/app_button.dart';
import 'package:easy_booking/core/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/widgets/actions/app_stepper.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('AppButton', () {
    testWidgets('has Paper height and invokes its callback', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpWidget(
        tester,
        AppButton(label: 'Continue', onPressed: () => taps++),
      );

      expect(tester.getSize(find.byType(AppButton)).height, 52);
      await tester.tap(find.text('Continue'));

      expect(taps, 1);
    });

    testWidgets('loading state blocks presses and shows progress', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpWidget(
        tester,
        AppButton(
          label: 'Continue',
          onPressed: () => taps++,
          isLoading: true,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
      await tester.tap(find.byType(FilledButton));

      expect(taps, 0);
    });
  });

  testWidgets('AppIconButton keeps a 44 pixel target', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpWidget(
      tester,
      AppIconButton(
        icon: const Icon(Icons.close),
        semanticLabel: 'Close',
        onPressed: () => taps++,
      ),
    );

    expect(tester.getSize(find.byType(AppIconButton)), const Size(44, 44));
    await tester.tap(find.byTooltip('Close'));

    expect(taps, 1);
  });

  testWidgets('AppChoiceChip reports the next selected state', (
    WidgetTester tester,
  ) async {
    bool? selected;
    await pumpWidget(
      tester,
      AppChoiceChip(
        label: 'Flexible',
        isSelected: false,
        onSelected: (bool value) => selected = value,
      ),
    );

    await tester.tap(find.text('Flexible'));

    expect(selected, isTrue);
  });

  testWidgets('AppStatusBadge exposes its status label', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      const AppStatusBadge(
        label: 'Confirmed',
        variant: AppStatusBadgeVariant.success,
        icon: Icon(Icons.check),
      ),
    );

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('AppStepper clamps controls at the configured bounds', (
    WidgetTester tester,
  ) async {
    int? changedValue;
    await pumpWidget(
      tester,
      AppStepper(
        value: 2,
        minimum: 2,
        maximum: 3,
        onChanged: (int value) => changedValue = value,
      ),
    );

    final IconButton decrease = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.remove),
    );
    expect(decrease.onPressed, isNull);

    await tester.tap(find.byTooltip('Increase'));

    expect(changedValue, 3);
  });
}
