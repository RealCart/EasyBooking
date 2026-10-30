import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';

import '../../helpers/router_harness.dart';

void main() {
  group('RoutePlaceholderScreen', () {
    testWidgets('shows a root header when nothing can be popped', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(tester);

      expect(find.byType(AppRootHeader), findsOneWidget);
      expect(find.byType(AppDetailHeader), findsNothing);
      expect(find.text('Экран в разработке'), findsOneWidget);
    });

    testWidgets('shows a back header on a pushed screen and pops on back', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      harness.router.push('/notifications');
      await tester.pumpAndSettle();

      expect(find.byType(AppDetailHeader), findsOneWidget);
      expect(find.text('Уведомления'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      expect(find.byType(AppRootHeader), findsOneWidget);
    });
  });
}
