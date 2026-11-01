import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_screen.dart';

import '../../../../helpers/router_harness.dart';

Future<RouterHarness> _pumpAt(WidgetTester tester, String location) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return RouterHarness.pump(tester, initialLocation: location);
}

const String _esentai = '/properties/esentai-city-84';

void main() {
  group('PropertyScreen', () {
    testWidgets('shows the property, its next arrival, and its price', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, _esentai);

      expect(find.byType(PropertyScreen), findsOneWidget);
      expect(find.text('Esentai City · квартира 84'), findsOneWidget);
      expect(find.text('Алматы · Аль-Фараби, 77/8'), findsOneWidget);
      expect(find.text('2 комнаты · 54 м² · до 4 гостей'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
      expect(find.text('22–25 окт · 3 ночи · 2 гостя'), findsOneWidget);
      expect(find.text('Booking.com · Airbnb'), findsOneWidget);
      // Imported 3 minutes before the mock's clock, 08:00.
      expect(find.text('Обновлены сегодня, 07:57'), findsOneWidget);
      expect(find.text(MoneyFormatter.tenge(42500)), findsOneWidget);
    });

    testWidgets('the heart removes the favorite', (WidgetTester tester) async {
      await _pumpAt(tester, _esentai);
      final Finder heart = find.byType(AppSavedIconButton);
      expect(tester.widget<AppSavedIconButton>(heart).isSaved, isTrue);

      await tester.tap(heart);
      await tester.pumpAndSettle();

      expect(tester.widget<AppSavedIconButton>(heart).isSaved, isFalse);
    });

    testWidgets('the settings tab and «Изменить» open the settings', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(tester, _esentai);

      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();
      expect(harness.location, '$_esentai/settings');

      harness.router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Изменить'));
      await tester.pumpAndSettle();
      expect(harness.location, '$_esentai/settings');
    });

    testWidgets('«Открыть» opens the booking of the next arrival', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(tester, _esentai);

      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      expect(harness.location, '/bookings/booking-1042');
    });

    testWidgets('«Календарь» switches to the calendar tab', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(tester, _esentai);

      await tester.tap(find.text('Календарь').last);
      await tester.pumpAndSettle();

      expect(harness.location, '/calendar');
    });

    testWidgets('an unknown property says it was not found', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties/missing');

      expect(find.text('Объект не найден'), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
    });
  });
}
