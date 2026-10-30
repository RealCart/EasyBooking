import 'package:flutter_test/flutter_test.dart';

import '../../helpers/router_harness.dart';

void main() {
  group('AppShellScreen', () {
    testWidgets('shows five navigation items with Today selected', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      for (final String label in <String>[
        'Сегодня',
        'Календарь',
        'Объекты',
        'Профиль',
      ]) {
        expect(
          find.descendant(
            of: harness.bottomNavigation,
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: harness.bottomNavigation,
          matching: find.bySemanticsLabel('Добавить'),
        ),
        findsOneWidget,
      );
      expect(harness.selectedItemIndex, 0);
    });

    testWidgets('items 0, 1, 3, 4 open branches 0, 1, 2, 3', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await harness.tapTab('Календарь');
      expect(harness.location, '/calendar');
      expect(harness.selectedItemIndex, 1);

      await harness.tapTab('Объекты');
      expect(harness.location, '/properties');
      expect(harness.selectedItemIndex, 3);

      await harness.tapTab('Профиль');
      expect(harness.location, '/profile');
      expect(harness.selectedItemIndex, 4);

      await harness.tapTab('Сегодня');
      expect(harness.location, '/today');
      expect(harness.selectedItemIndex, 0);
    });

    testWidgets('switching tabs keeps each tab stack', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);
      await harness.go('/calendar/occupancy');

      await harness.tapTab('Сегодня');
      await harness.tapTab('Календарь');

      expect(harness.location, '/calendar/occupancy');
    });

    testWidgets('tapping the active tab returns it to its first screen', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);
      await harness.go('/calendar/occupancy');
      expect(harness.selectedItemIndex, 1);

      await harness.tapTab('Календарь');

      expect(harness.location, '/calendar');
    });

    testWidgets('Add opens add-property over the bottom navigation', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tester.tap(find.bySemanticsLabel('Добавить'));
      await tester.pumpAndSettle();

      expect(harness.location, '/add-property');
      expect(find.text('Добавить квартиру'), findsOneWidget);
      expect(harness.bottomNavigation, findsNothing);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      expect(harness.bottomNavigation, findsOneWidget);
    });

    testWidgets('property details pushed from Today cover the navigation', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      harness.router.push('/properties/42');
      await tester.pumpAndSettle();

      expect(find.text('Ваш объект'), findsOneWidget);
      expect(harness.bottomNavigation, findsNothing);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      expect(harness.selectedItemIndex, 0);
    });

    testWidgets('favorite properties keep the navigation on Properties', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await harness.go('/properties/favorites');

      expect(find.text('Избранные'), findsOneWidget);
      expect(harness.bottomNavigation, findsOneWidget);
      expect(harness.selectedItemIndex, 3);
    });
  });
}
