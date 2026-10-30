import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/widgets/navigation/app_resend_timer_row.dart';
import 'package:easy_booking/core/widgets/navigation/app_section_header.dart';

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
