import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/router/route_not_found_screen.dart';

import '../../helpers/router_harness.dart';

void main() {
  testWidgets('RouteNotFoundScreen explains the error and opens today', (
    WidgetTester tester,
  ) async {
    final RouterHarness harness = await RouterHarness.pump(
      tester,
      initialLocation: '/old-link',
    );

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.text('Страница не найдена'), findsOneWidget);
    expect(find.text('Ссылка устарела или указана с ошибкой.'), findsOneWidget);

    await tester.tap(find.text('На главную'));
    await tester.pumpAndSettle();

    expect(harness.location, '/today');
    expect(find.byType(RouteNotFoundScreen), findsNothing);
    expect(harness.bottomNavigation, findsOneWidget);
  });
}
