import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_resend_timer_row.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_section_header.dart';

void main() {
  testWidgets('AppSectionHeader invokes its optional action', (
    WidgetTester tester,
  ) async {
    int actionCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: AppSectionHeader(
          title: 'Ближайшие брони',
          subtitle: 'На этой неделе',
          actionLabel: 'Все',
          onAction: () => actionCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('Все'));
    await tester.pump();

    expect(actionCount, 1);
    expect(find.text('Ближайшие брони'), findsOneWidget);
    expect(find.text('На этой неделе'), findsOneWidget);
  });

  testWidgets('AppResendTimerRow blocks resend while timer is active', (
    WidgetTester tester,
  ) async {
    int resendCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: AppResendTimerRow(
          prompt: 'Не получили код?',
          actionLabel: 'Отправить снова',
          remaining: const Duration(seconds: 30),
          onResend: () => resendCount += 1,
        ),
      ),
    );

    expect(find.text('00:30'), findsOneWidget);
    await tester.tap(find.text('Отправить снова'));
    await tester.pump();
    expect(resendCount, 0);
  });

  testWidgets('AppResendTimerRow invokes resend when timer has elapsed', (
    WidgetTester tester,
  ) async {
    int resendCount = 0;

    await tester.pumpWidget(
      _TestApp(
        child: AppResendTimerRow(
          prompt: 'Не получили код?',
          actionLabel: 'Отправить снова',
          remaining: Duration.zero,
          onResend: () => resendCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('Отправить снова'));
    await tester.pump();
    expect(resendCount, 1);
  });

  group('AppResendTimerRow detailed layout', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      required Duration? remaining,
      required VoidCallback onResend,
      String subtitle = 'Можно через 00:28',
      Widget? leading = const Icon(Icons.schedule),
    }) {
      return tester.pumpWidget(
        _TestApp(
          child: AppResendTimerRow(
            prompt: 'Код не пришёл?',
            actionLabel: 'Отправить код повторно',
            subtitle: subtitle,
            leading: leading,
            remaining: remaining,
            onResend: onResend,
          ),
        ),
      );
    }

    testWidgets('while waiting shows subtitle, leading and timer, disabled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int resendCount = 0;
      await pumpRow(
        tester,
        remaining: const Duration(seconds: 28),
        onResend: () => resendCount++,
      );

      expect(find.text('Отправить код повторно'), findsOneWidget);
      expect(find.text('Можно через 00:28'), findsOneWidget);
      expect(find.text('00:28'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Отправить код повторно')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );

      await tester.tap(find.text('Отправить код повторно'));
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pump();
      expect(resendCount, 0);
      handle.dispose();
    });

    testWidgets('at zero hides the timer and the whole row resends', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int resendCount = 0;
      await pumpRow(
        tester,
        remaining: Duration.zero,
        subtitle: 'Отправим новый код',
        onResend: () => resendCount++,
      );

      expect(find.text('00:00'), findsNothing);
      expect(find.text('Отправим новый код'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Отправить код повторно')),
        isSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.text('Отправить код повторно'));
      await tester.tap(find.text('Отправим новый код'));
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pump();
      expect(resendCount, 3);
      handle.dispose();
    });

    testWidgets('a subtitle alone switches to the detailed layout', (
      WidgetTester tester,
    ) async {
      int resendCount = 0;
      await pumpRow(
        tester,
        remaining: null,
        leading: null,
        subtitle: 'Отправим новый код',
        onResend: () => resendCount++,
      );

      expect(find.byType(TextButton), findsNothing);
      expect(find.text('Отправим новый код'), findsOneWidget);

      await tester.tap(find.text('Отправим новый код'));
      expect(resendCount, 1);
    });
  });
}

final class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );
  }
}
