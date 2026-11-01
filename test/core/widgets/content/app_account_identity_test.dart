import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_account_identity.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppAccountIdentity', () {
    testWidgets('without a photo shows the initials of the first and last '
        'words', (WidgetTester tester) async {
      await _pump(
        tester,
        const AppAccountIdentity(
          name: 'Бексултан Ерланович Нишанбек',
          details: 'Владелец · Алматы',
        ),
      );

      expect(find.text('БН'), findsOneWidget);
      expect(find.text('Владелец · Алматы'), findsOneWidget);
    });

    testWidgets('a single name gives one initial', (WidgetTester tester) async {
      await _pump(
        tester,
        const AppAccountIdentity(name: 'айжан', details: 'Менеджер'),
      );

      expect(find.text('А'), findsOneWidget);
    });

    testWidgets('the action calls back; no action shows no button', (
      WidgetTester tester,
    ) async {
      int actionCount = 0;
      await _pump(
        tester,
        AppAccountIdentity(
          name: 'Бексултан Нишанбек',
          details: 'Владелец',
          actionLabel: 'Редактировать профиль',
          onAction: () => actionCount += 1,
        ),
      );

      await tester.tap(find.text('Редактировать профиль'));
      expect(actionCount, 1);

      await _pump(
        tester,
        const AppAccountIdentity(name: 'Бексултан Нишанбек', details: 'x'),
      );
      expect(find.text('Редактировать профиль'), findsNothing);
    });
  });
}
