import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_calendar_event_row.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_day_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_bloc/calendar_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/screens/calendar_screen.dart';

import '../../../../helpers/fake_calendar_repository.dart';
import '../../../../helpers/router_harness.dart';

void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<RouterHarness> _pumpCalendar(WidgetTester tester) {
  _usePhoneSize(tester);
  return RouterHarness.pump(tester, initialLocation: '/calendar');
}

void main() {
  group('CalendarScreen', () {
    testWidgets('today shows the week and the three events of the design', (
      WidgetTester tester,
    ) async {
      await _pumpCalendar(tester);

      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.text('Октябрь 2026'), findsOneWidget);
      for (final String day in <String>['19', '20', '21', '22', '23', '24']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.text('22 октября, четверг'), findsOneWidget);
      expect(find.text('Выезд · Арман'), findsOneWidget);
      expect(find.text('Ключи оставит в сейфе'), findsOneWidget);
      expect(find.text('Заезд · Айжан'), findsOneWidget);
      expect(find.text('3 ночи · договор подписан'), findsOneWidget);
      expect(find.text('Заезд · Данияр'), findsOneWidget);
      expect(find.text('2 ночи · ждём подпись'), findsOneWidget);
      expect(find.text('Все календари обновлены'), findsOneWidget);
      expect(find.text('Последняя проверка сегодня, 07:57'), findsOneWidget);
    });

    testWidgets('another day of the week shows its events', (
      WidgetTester tester,
    ) async {
      await _pumpCalendar(tester);

      await tester.tap(find.text('25'));
      await tester.pumpAndSettle();

      expect(find.text('25 октября, воскресенье'), findsOneWidget);
      expect(find.text('Выезд · Айжан'), findsOneWidget);
      expect(find.text('Заезд · Тимур'), findsOneWidget);
      expect(find.text('Заезд · Данияр'), findsNothing);
    });

    testWidgets('a day without events says so', (WidgetTester tester) async {
      await _pumpCalendar(tester);

      await tester.tap(find.text('21'));
      await tester.pumpAndSettle();

      expect(find.byType(AppCalendarEventRow), findsNothing);
      expect(find.text('Ни заездов, ни выездов'), findsOneWidget);
    });

    testWidgets('favorites hide the events of other properties', (
      WidgetTester tester,
    ) async {
      await _pumpCalendar(tester);

      await tester.tap(find.text('Избранные'));
      await tester.pumpAndSettle();

      expect(find.byType(AppCalendarEventRow), findsNWidgets(2));
      expect(find.text('Заезд · Данияр'), findsNothing);
    });

    testWidgets('an event opens its booking', (WidgetTester tester) async {
      final RouterHarness harness = await _pumpCalendar(tester);

      await tester.tap(find.text('Заезд · Айжан'));
      await tester.pumpAndSettle();

      expect(harness.location, '/bookings/booking-1042');
    });

    testWidgets('«Неделя» and the menu open the calendar tools', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpCalendar(tester);

      await tester.tap(find.text('Неделя'));
      await tester.pumpAndSettle();
      expect(harness.location, '/calendar/occupancy');

      await harness.go('/calendar');
      await tester.tap(find.bySemanticsLabel('Ещё'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Каналы'));
      await tester.pumpAndSettle();
      expect(harness.location, '/calendar/channels');
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      _usePhoneSize(tester);
      final FakeCalendarRepository repository = FakeCalendarRepository()
        ..dayFailure = const ConnectionFailure();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<CalendarBloc>(
            create: (_) =>
                CalendarBloc(getCalendarDay: GetCalendarDayUsecase(repository))
                  ..add(const CalendarRequested()),
            child: const CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить календарь'), findsOneWidget);

      repository.dayFailure = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Заезд · Айжан'), findsOneWidget);
    });
  });
}
