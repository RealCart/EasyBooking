import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/features/home/presentation/screens/home_screen.dart';

import '../../../../helpers/router_harness.dart';

void main() {
  group('HomeScreen', () {
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('today opens with the arrivals, tasks, and sync status', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Заезды · 2'), findsOneWidget);
      expect(find.text('Выезды · 1'), findsOneWidget);
      expect(find.text('Проживают · 3'), findsOneWidget);

      expect(find.byType(AppArrivalCard), findsNWidgets(2));
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('Esentai City · 84'), findsOneWidget);
      expect(find.text('Айжан · 3 ночи'), findsOneWidget);
      expect(find.text('К заезду всё готово'), findsOneWidget);
      expect(find.text('18:30'), findsOneWidget);
      expect(find.text('Данияр · 2 ночи'), findsOneWidget);
      expect(find.text('Ожидает договор'), findsOneWidget);

      expect(find.text('Перед заездом'), findsOneWidget);
      expect(find.text('Договор Данияра'), findsOneWidget);
      expect(find.text('До 13:00'), findsOneWidget);
      expect(find.text('Календари обновлены в 09:38'), findsOneWidget);
      expect(find.text('Booking.com и Airbnb · 4 объекта'), findsOneWidget);
    });

    testWidgets('a scope chip switches the stay cards', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(tester);

      await tester.tap(find.text('Выезды · 1'));
      await tester.pumpAndSettle();

      expect(find.byType(AppArrivalCard), findsOneWidget);
      expect(find.text('Nurly Tau · 12'), findsOneWidget);
      expect(find.text('12:00'), findsOneWidget);
      expect(find.text('Уборка назначена'), findsOneWidget);
      expect(find.text('Esentai City · 84'), findsNothing);

      await tester.tap(find.text('Проживают · 3'));
      await tester.pumpAndSettle();

      expect(find.byType(AppArrivalCard), findsNWidgets(3));
      expect(find.textContaining('Мадина'), findsOneWidget);
      expect(find.textContaining('до '), findsNWidgets(3));
    });

    testWidgets('a stay card opens its property', (WidgetTester tester) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tapVisible(tester, find.text('Esentai City · 84'));

      expect(harness.location, '/properties/esentai-city-84');
    });

    testWidgets('the bell opens notifications', (WidgetTester tester) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tapVisible(tester, find.bySemanticsLabel('Уведомления'));

      expect(harness.location, '/notifications');
    });

    testWidgets('a contract task opens the contract', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tapVisible(tester, find.text('Договор Данияра'));

      expect(harness.location, '/contracts/samal-daniyar');
    });

    testWidgets('remind shows a confirmation and stays on today', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tapVisible(tester, find.text('Напомнить'));

      expect(find.text('Напоминание отправлено'), findsOneWidget);
      expect(harness.location, '/today');
    });

    testWidgets('the sync summary opens the channels in the calendar tab', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      await tapVisible(tester, find.text('Календари обновлены в 09:38'));

      expect(harness.location, '/calendar/channels');
      expect(harness.selectedItemIndex, 1);
    });
  });
}
