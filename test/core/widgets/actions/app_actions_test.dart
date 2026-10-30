import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/core/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/widgets/actions/app_primary_button.dart';
import 'package:easy_booking/core/widgets/actions/app_secondary_button.dart';
import 'package:easy_booking/core/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/widgets/actions/app_stepper.dart';
import 'package:easy_booking/core/widgets/actions/app_text_button.dart';

void main() {
  Future<void> pumpWidget(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  group('AppPrimaryButton', () {
    testWidgets('has Paper height and invokes its callback', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpWidget(
        tester,
        AppPrimaryButton(label: 'Continue', onPressed: () => taps++),
      );

      expect(tester.getSize(find.byType(AppPrimaryButton)).height, 52);
      await tester.tap(find.text('Continue'));

      expect(taps, 1);
    });

    testWidgets('loading state blocks presses and shows progress', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpWidget(
        tester,
        AppPrimaryButton(
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

    testWidgets('keeps its custom Paper hover and pressed colors', (
      WidgetTester tester,
    ) async {
      await pumpWidget(
        tester,
        AppPrimaryButton(label: 'Continue', onPressed: () {}),
      );

      final FilledButton button = tester.widget(find.byType(FilledButton));
      expect(
        button.style!.backgroundColor!.resolve(<WidgetState>{
          WidgetState.hovered,
        }),
        AppColors.accentHover,
      );
      expect(
        button.style!.backgroundColor!.resolve(<WidgetState>{
          WidgetState.pressed,
        }),
        AppColors.accentPressed,
      );
    });
  });

  testWidgets('button styles use Paper sizes and disabled colors', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppPrimaryButton(label: 'Continue', onPressed: null),
          AppSecondaryButton(label: 'Open', onPressed: null),
        ],
      ),
    );

    expect(tester.getSize(find.byType(AppPrimaryButton)).height, 52);
    expect(tester.getSize(find.byType(AppSecondaryButton)).height, 48);
    final FilledButton primary = tester.widget(find.byType(FilledButton));
    expect(
      primary.style!.backgroundColor!.resolve(<WidgetState>{
        WidgetState.disabled,
      }),
      AppColors.border,
    );
    expect(
      primary.style!.foregroundColor!.resolve(<WidgetState>{
        WidgetState.disabled,
      }),
      AppColors.onAccent,
    );
    final OutlinedButton secondary = tester.widget(find.byType(OutlinedButton));
    expect(
      secondary.style!.side!.resolve(<WidgetState>{})!.color,
      AppColors.text,
    );
    expect(
      secondary.style!.overlayColor!.resolve(<WidgetState>{
        WidgetState.hovered,
      }),
      Colors.transparent,
    );
  });

  testWidgets('compact primary button uses the footer height', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      const AppPrimaryButton.compact(label: 'Continue', onPressed: null),
    );
    expect(tester.getSize(find.byType(AppPrimaryButton)).height, 48);
  });

  testWidgets('buttons fill bounded width and fit unbounded horizontal space', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppPrimaryButton(label: 'Continue', onPressed: () {}),
            AppSecondaryButton(label: 'Open', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppPrimaryButton)).width, 240);
    expect(tester.getSize(find.byType(AppSecondaryButton)).width, 240);

    await pumpWidget(
      tester,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            AppPrimaryButton(label: 'Continue', onPressed: () {}),
            AppSecondaryButton(label: 'Open', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppPrimaryButton)).width, greaterThan(0));
    expect(
      tester.getSize(find.byType(AppSecondaryButton)).width,
      greaterThan(0),
    );
  });

  testWidgets('buttons grow to accommodate large text', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppPrimaryButton(label: 'Continue', onPressed: () {}),
            AppSecondaryButton(label: 'Open', onPressed: () {}),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(AppPrimaryButton)).height,
      greaterThan(52),
    );
    expect(
      tester.getSize(find.byType(AppSecondaryButton)).height,
      greaterThan(48),
    );
  });

  testWidgets('expanded text action handles bounded and unbounded widths', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      SizedBox(
        width: 240,
        child: AppTextButton.accent(
          label: 'Edit',
          onPressed: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(AppTextButton)).width, 240);
    await pumpWidget(
      tester,
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AppTextButton.accent(
          label: 'Edit',
          onPressed: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppTextButton)).width, greaterThan(0));
  });

  testWidgets('text action treatments expose correct color and decoration', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppTextButton.underlined(
            label: 'Edit',
            onPressed: () {},
          ),
          AppTextButton.accent(label: 'Remind', onPressed: () {}),
          AppTextButton.muted(
            label: 'Cancel',
            onPressed: () {},
          ),
        ],
      ),
    );

    final List<TextButton> buttons = tester
        .widgetList<TextButton>(find.byType(TextButton))
        .toList();
    expect(
      buttons[0].style!.textStyle!.resolve(<WidgetState>{})!.decoration,
      TextDecoration.underline,
    );
    expect(
      buttons[0].style!.foregroundColor!.resolve(<WidgetState>{}),
      AppColors.text,
    );
    expect(
      buttons[1].style!.foregroundColor!.resolve(<WidgetState>{}),
      AppColors.accent,
    );
    expect(
      buttons[2].style!.foregroundColor!.resolve(<WidgetState>{}),
      AppColors.secondaryText,
    );
  });

  testWidgets('saved action uses selected appearance and triggers callback', (
    WidgetTester tester,
  ) async {
    int taps = 0;
    await pumpWidget(
      tester,
      AppSavedIconButton(isSaved: true, onPressed: () => taps++),
    );
    final IconButton button = tester.widget(find.byType(IconButton));
    expect(
      button.style!.backgroundColor!.resolve(<WidgetState>{}),
      AppColors.text,
    );
    expect(
      button.style!.side!.resolve(<WidgetState>{})!.color,
      AppColors.border,
    );
    await tester.tap(find.bySemanticsLabel('Remove from saved'));
    expect(taps, 1);
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
    await tester.tap(find.bySemanticsLabel('Close'));

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

  testWidgets('AppChoiceChip selected state stays visible and accessible', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      AppChoiceChip(label: 'Apartment', isSelected: true, onSelected: (_) {}),
    );
    expect(tester.getSize(find.byType(AppChoiceChip)).height, 44);
    final Ink chip = tester.widget<Ink>(
      find
          .descendant(
            of: find.byType(AppChoiceChip),
            matching: find.byType(Ink),
          )
          .first,
    );
    expect((chip.decoration! as BoxDecoration).color, AppColors.text);
  });

  testWidgets('AppChoiceChip exposes an actionable semantic button', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    bool? selected;
    await pumpWidget(
      tester,
      AppChoiceChip(
        label: 'Apartment',
        isSelected: false,
        onSelected: (bool value) => selected = value,
      ),
    );

    final SemanticsNode node = tester.getSemantics(find.byType(AppChoiceChip));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(
      node.id,
      SemanticsAction.tap,
    );
    expect(selected, isTrue);
    handle.dispose();
  });

  testWidgets('AppStatusBadge wraps long text at large scale', (
    WidgetTester tester,
  ) async {
    await pumpWidget(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: SizedBox(
          width: 100,
          child: AppStatusBadge(label: 'Awaiting guest signature'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppStatusBadge)).height, greaterThan(32));
  });

  testWidgets(
    'text action accepts compact typography while keeping underline',
    (
      WidgetTester tester,
    ) async {
      await pumpWidget(
        tester,
        AppTextButton.underlined(
          label: 'Replace',
          onPressed: () {},
        ),
      );
      final TextButton button = tester.widget(find.byType(TextButton));
      final TextStyle style = button.style!.textStyle!.resolve(
        <WidgetState>{},
      )!;
      expect(style.fontSize, 12);
      expect(style.decoration, TextDecoration.underline);
    },
  );

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
      find.descendant(
        of: find.bySemanticsLabel('Decrease'),
        matching: find.byType(IconButton),
      ),
    );
    expect(decrease.onPressed, isNull);

    await tester.tap(find.bySemanticsLabel('Increase'));

    expect(changedValue, 3);
  });
}
