import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/occupancy_bloc/occupancy_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/screens/occupancy_screen.dart';

import '../../../../helpers/fake_occupancy_repository.dart';

/// The 430 × 932 phone of the design.
void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// A destination that only shows where the router went.
Widget _destination(GoRouterState state) {
  return Scaffold(body: Text('route:${state.uri}'));
}

/// Pumps [OccupancyScreen] at `/` under its own [BlocProvider] over
/// [repository], with the routes it opens.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeOccupancyRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.occupancy.name,
        path: '/',
        builder: (_, _) => BlocProvider<OccupancyBloc>(
          create: (_) => OccupancyBloc(
            getOccupancyWeek: GetOccupancyWeekUsecase(repository),
          )..add(const OccupancyRequested()),
          child: const OccupancyScreen(),
        ),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.channels.name,
            path: AppRoutes.channels.path,
            builder: (_, GoRouterState state) => _destination(state),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.calendar.name,
        path: AppRoutes.calendar.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
      GoRoute(
        name: AppRoutes.booking.name,
        path: AppRoutes.booking.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
      GoRoute(
        name: AppRoutes.calendarConflict.name,
        path: AppRoutes.calendarConflict.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

String _location(GoRouter router) => router.state.uri.toString();

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('OccupancyScreen', () {
    testWidgets('shows a skeleton and no days before the first week', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository()
        ..holdWeeks = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Объект'), findsNothing);

      repository.heldWeeks.single.complete(
        Right<Failure, OccupancyWeekEntity>(
          testOccupancyWeek(occupancyTestWeekStart),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Объект'), findsOneWidget);
    });

    testWidgets('the week shows its days, rows, bars, and sync state', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();

      await _pump(tester, repository);

      expect(repository.requests.single, (date: null, favoritesOnly: false));
      expect(find.text('Занятость'), findsOneWidget);
      expect(find.text('Октябрь 2026'), findsOneWidget);
      expect(find.text('19–25 октября'), findsOneWidget);
      expect(find.text('Пн\n19'), findsOneWidget);
      expect(find.text('Чт\n22'), findsOneWidget);
      expect(find.text('Вс\n25'), findsOneWidget);
      expect(find.text('Esentai · 84'), findsOneWidget);
      expect(find.text('Mega · 126'), findsOneWidget);
      expect(find.text('Samal · 12'), findsOneWidget);
      expect(find.text(MoneyFormatter.tenge(42500)), findsOneWidget);
      expect(find.text('Айжан · Airbnb'), findsOneWidget);
      expect(find.text('Марат · напрямую'), findsOneWidget);
      expect(find.text('Данияр · Booking'), findsOneWidget);
      expect(find.text('Ремонт'), findsOneWidget);
      expect(find.text('Все каналы обновлены'), findsOneWidget);
      expect(find.text('Последняя проверка сегодня в 09:38'), findsOneWidget);
    });

    testWidgets('an unhealthy sync says so and opens the channels', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository()
        ..isSyncHealthy = false;
      final GoRouter router = await _pump(tester, repository);

      expect(find.text('Не все каналы обновились'), findsOneWidget);

      await tester.ensureVisible(find.text('Не все каналы обновились'));
      await _tap(tester, find.text('Не все каналы обновились'));

      expect(_location(router), '/channels');
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository()
        ..weekFailure = const ConnectionFailure();

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить занятость'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('Объект'), findsNothing);

      repository.weekFailure = null;
      await _tap(tester, find.text('Повторить'));

      expect(repository.requests, hasLength(2));
      expect(find.text('Не удалось загрузить занятость'), findsNothing);
      expect(find.text('Esentai · 84'), findsOneWidget);
    });

    testWidgets('a failed week change keeps the days and offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      await _pump(tester, repository);
      repository.weekFailure = const TimeoutFailure();

      await _tap(tester, find.bySemanticsLabel('Следующая неделя'));

      expect(find.text('Пн\n26'), findsOneWidget);
      expect(find.text('Не удалось загрузить занятость'), findsOneWidget);

      repository.weekFailure = null;
      await _tap(tester, find.text('Повторить'));

      expect(repository.requests.last.date, DateTime(2026, 10, 26));
      expect(find.text('Не удалось загрузить занятость'), findsNothing);
    });

    testWidgets('no properties and no favorites have their own texts', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository()
        ..rows = const <OccupancyRowEntity>[];
      await _pump(tester, repository);

      expect(find.text('Пока нет квартир'), findsOneWidget);

      await _tap(tester, find.text('Избранные'));

      expect(repository.requests.last, (
        date: occupancyTestWeekStart,
        favoritesOnly: true,
      ));
      expect(find.text('Нет избранных квартир'), findsOneWidget);
      expect(find.text('Пока нет квартир'), findsNothing);
    });

    testWidgets('the scope filter asks for favorites, then for all', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      await _pump(tester, repository);

      await _tap(tester, find.text('Избранные'));
      expect(repository.requests.last.favoritesOnly, isTrue);

      await _tap(tester, find.text('Все объекты'));
      expect(repository.requests.last.favoritesOnly, isFalse);
    });

    testWidgets('the chevrons and «Сегодня» move between weeks', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      await _pump(tester, repository);

      await _tap(tester, find.bySemanticsLabel('Следующая неделя'));
      expect(repository.requests.last.date, DateTime(2026, 10, 26));
      expect(find.text('26 октября – 1 ноября'), findsOneWidget);
      expect(find.text('Esentai · 84'), findsNothing);

      await _tap(tester, find.bySemanticsLabel('Предыдущая неделя'));
      await _tap(tester, find.bySemanticsLabel('Предыдущая неделя'));
      expect(repository.requests.last.date, DateTime(2026, 10, 12));
      expect(find.text('12–18 октября'), findsOneWidget);

      await _tap(tester, find.text('Сегодня'));
      expect(repository.requests.last, (date: null, favoritesOnly: false));
      expect(find.text('19–25 октября'), findsOneWidget);
    });

    testWidgets('while another week loads, its days show over a skeleton', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      await _pump(tester, repository);
      repository.holdWeeks = true;

      await tester.tap(find.bySemanticsLabel('Следующая неделя'));
      await tester.pump();

      expect(find.text('Пн\n26'), findsOneWidget);
      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Esentai · 84'), findsNothing);
    });

    testWidgets('a conflicting stay opens the conflict and reloads after', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      final GoRouter router = await _pump(tester, repository);

      await _tap(tester, find.text('Айжан · Airbnb'));

      expect(_location(router), '/calendar-conflicts/c1');

      router.pop();
      await tester.pumpAndSettle();

      expect(_location(router), '/');
      expect(repository.requests, hasLength(2));
    });

    testWidgets('another stay opens its booking', (WidgetTester tester) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      final GoRouter router = await _pump(tester, repository);

      await _tap(tester, find.text('Данияр · Booking'));

      expect(_location(router), '/bookings/b3');
    });

    testWidgets('closed dates open nothing', (WidgetTester tester) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(find.text('Ремонт'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_location(router), '/');
      expect(repository.requests, hasLength(1));
    });

    testWidgets('the menu opens the day calendar and the channels', (
      WidgetTester tester,
    ) async {
      final FakeOccupancyRepository repository = FakeOccupancyRepository();
      final GoRouter router = await _pump(tester, repository);

      await _tap(tester, find.bySemanticsLabel('Ещё'));
      await _tap(tester, find.text('Календарь по дням'));

      expect(_location(router), '/calendar');
    });
  });
}
