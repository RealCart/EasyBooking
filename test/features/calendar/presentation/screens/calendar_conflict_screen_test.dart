import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_conflict_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/calendar_conflict_bloc/calendar_conflict_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/screens/calendar_conflict_screen.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/conflict_booking_tile.dart';

import '../../../../helpers/fake_calendar_conflicts_repository.dart';

/// The 430 × 932 phone of the design.
void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [CalendarConflictScreen] for `c1` at `/conflict`, over a `/` page
/// it can pop back to, under its own [BlocProvider] over [repository].
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeCalendarConflictsRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    initialLocation: '/conflict',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('occupancy')),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.calendarConflict.name,
            path: 'conflict',
            builder: (_, _) => BlocProvider<CalendarConflictBloc>(
              create: (_) => CalendarConflictBloc(
                getConflict: GetCalendarConflictUsecase(repository),
                resolveConflict: ResolveCalendarConflictUsecase(repository),
              )..add(const CalendarConflictRequested('c1')),
              child: const CalendarConflictScreen(conflictId: 'c1'),
            ),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.booking.name,
        path: AppRoutes.booking.path,
        builder: (_, GoRouterState state) =>
            Scaffold(body: Text('route:${state.uri}')),
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

/// The tile titled [title].
Finder _tile(String title) {
  return find.ancestor(
    of: find.text(title),
    matching: find.byType(ConflictBookingTile),
  );
}

final Finder _keepAirbnb = find.widgetWithText(FilledButton, 'Оставить Airbnb');
final Finder _keepDirect = find.widgetWithText(
  OutlinedButton,
  'Оставить ручную',
);

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

void main() {
  group('CalendarConflictScreen', () {
    testWidgets('shows a skeleton and no actions while loading', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()..holdConflict = true;

      await _pump(tester, repository, settle: false);

      expect(repository.conflictRequests, <String>['c1']);
      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Оставить Airbnb'), findsNothing);
    });

    testWidgets('shows both bookings and the two keep actions', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeCalendarConflictsRepository());

      expect(find.text('Конфликт календарей'), findsOneWidget);
      expect(find.text('1 из 1'), findsOneWidget);
      expect(find.text('Пересечение бронирований'), findsOneWidget);
      expect(
        find.text(
          'Esentai City · квартира 84\n'
          '24–25 октября пересекаются в двух источниках.',
        ),
        findsOneWidget,
      );
      expect(find.text('Airbnb · Айжан'), findsOneWidget);
      expect(find.text('Ручная · Марат'), findsOneWidget);
      expect(find.text('Подтверждена'), findsNWidgets(2));
      expect(find.text('Что произойдёт'), findsOneWidget);
      expect(_isEnabled(tester, _keepAirbnb), isTrue);
      expect(_isEnabled(tester, _keepDirect), isTrue);
    });

    testWidgets('an unconfirmed booking tells its creation day relative to '
        'the source time', (WidgetTester tester) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..conflictResult = Right<Failure, CalendarConflictEntity>(
              testCalendarConflict(isDirectConfirmed: false),
            );

      await _pump(tester, repository);

      expect(
        find.descendant(
          of: _tile('Ручная · Марат'),
          matching: find.text('Создана вчера'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tile('Airbnb · Айжан'),
          matching: find.text('Подтверждена'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a booking tile opens the booking', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakeCalendarConflictsRepository(),
      );

      await tester.tap(find.text('Ручная · Марат'));
      await tester.pumpAndSettle();

      expect(_location(router), '/bookings/$conflictTestDirectBookingId');
    });

    testWidgets('«Оставить Airbnb» keeps the first booking', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository();
      await _pump(tester, repository);

      await tester.tap(_keepAirbnb);
      await tester.pumpAndSettle();

      expect(repository.resolveRequests.single, (
        conflictId: 'c1',
        keepBookingId: conflictTestAirbnbBookingId,
      ));
      expect(
        find.descendant(
          of: _tile('Airbnb · Айжан'),
          matching: find.text('Сохранена'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _tile('Ручная · Марат'),
          matching: find.text('Отменена'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('«Оставить ручную» keeps the second booking', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository();
      await _pump(tester, repository);

      await tester.tap(_keepDirect);
      await tester.pumpAndSettle();

      expect(
        repository.resolveRequests.single.keepBookingId,
        conflictTestDirectBookingId,
      );
      expect(
        find.descendant(
          of: _tile('Ручная · Марат'),
          matching: find.text('Сохранена'),
        ),
        findsOneWidget,
      );
      expect(find.text('Оставлена бронь Ручная · Марат'), findsOneWidget);
    });

    testWidgets('once resolved it says so and «Готово» leaves', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakeCalendarConflictsRepository(),
      );

      await tester.tap(_keepAirbnb);
      await tester.pumpAndSettle();

      // The title and the snackbar.
      expect(find.text('Конфликт решён'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Конфликт решён'),
        ),
        findsOneWidget,
      );
      expect(find.text('Оставить Airbnb'), findsNothing);
      expect(find.text('Оставить ручную'), findsNothing);

      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();

      expect(_location(router), '/');
      expect(find.text('occupancy'), findsOneWidget);
    });

    testWidgets('while resolving, both keep actions are disabled', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()..holdResolve = true;
      await _pump(tester, repository);

      await tester.tap(_keepDirect);
      await tester.pump();

      expect(
        _isEnabled(tester, find.byType(FilledButton)),
        isFalse,
        reason: 'Оставить Airbnb',
      );
      expect(_isEnabled(tester, _keepDirect), isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(repository.resolveRequests, hasLength(1));

      repository.heldResolves.single.complete(
        const Left<Failure, CalendarConflictEntity>(TimeoutFailure()),
      );
      await tester.pumpAndSettle();

      expect(_isEnabled(tester, _keepAirbnb), isTrue);
      expect(_isEnabled(tester, _keepDirect), isTrue);
    });

    testWidgets('a failed resolve shows its message and keeps the choice', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..resolveResult = const Left<Failure, CalendarConflictEntity>(
              ConnectionFailure(),
            );
      await _pump(tester, repository);

      await tester.tap(_keepAirbnb);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Нет подключения к интернету'),
        ),
        findsOneWidget,
      );
      expect(find.text('Пересечение бронирований'), findsOneWidget);
      expect(_isEnabled(tester, _keepAirbnb), isTrue);
    });

    testWidgets('an unknown conflict is not found, without a retry', (
      WidgetTester tester,
    ) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..conflictResult = const Left<Failure, CalendarConflictEntity>(
              ServerFailure(statusCode: 404),
            );

      await _pump(tester, repository);

      expect(find.text('Конфликт не найден'), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('another failure offers a retry', (WidgetTester tester) async {
      final FakeCalendarConflictsRepository repository =
          FakeCalendarConflictsRepository()
            ..conflictResult = const Left<Failure, CalendarConflictEntity>(
              ConnectionFailure(),
            );
      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить конфликт'), findsOneWidget);

      repository.conflictResult = Right<Failure, CalendarConflictEntity>(
        testCalendarConflict(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.conflictRequests, <String>['c1', 'c1']);
      expect(find.text('Пересечение бронирований'), findsOneWidget);
    });
  });
}
