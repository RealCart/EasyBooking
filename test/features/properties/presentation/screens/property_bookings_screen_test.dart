import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_bookings_bloc/property_bookings_bloc.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_bookings_screen.dart';

import '../../../../helpers/fake_properties_repository.dart';
import '../../../../helpers/fake_property_management_repository.dart';

const String _propertyLocation = '/properties/p1';

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

/// The property at `/properties/p1` with the bookings screen on top of it,
/// and the routes the screen opens.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertyManagementRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    initialLocation: '$_propertyLocation/${AppRoutes.propertyBookings.path}',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.property.name,
        path: AppRoutes.property.path,
        builder: (_, GoRouterState state) => _destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.propertyBookings.name,
            path: AppRoutes.propertyBookings.path,
            builder: (_, GoRouterState state) =>
                BlocProvider<PropertyBookingsBloc>(
                  create: (_) => PropertyBookingsBloc(
                    getBookings: GetPropertyBookingsUsecase(repository),
                  )..add(const PropertyBookingsRequested('p1')),
                  child: const PropertyBookingsScreen(propertyId: 'p1'),
                ),
          ),
          GoRoute(
            name: AppRoutes.propertySettings.name,
            path: AppRoutes.propertySettings.path,
            builder: (_, GoRouterState state) => _destination(state),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.newBooking.name,
        path: AppRoutes.newBooking.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
      GoRoute(
        name: AppRoutes.booking.name,
        path: AppRoutes.booking.path,
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

PropertyBookingsEntity _withoutBookings() {
  return PropertyBookingsEntity(
    property: testProperties().first,
    upcoming: const <PropertyBookingEntity>[],
    past: const <PropertyBookingEntity>[],
    receivedAt: propertiesTestNow,
  );
}

void main() {
  group('PropertyBookingsScreen', () {
    testWidgets('shows a skeleton until the bookings load', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()..holdBookings = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Айжан Сарсенова'), findsNothing);

      repository.heldBookings.single.complete(
        Right<Failure, PropertyBookingsEntity>(testPropertyBookings()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });

    testWidgets('lists the upcoming bookings grouped by month', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();

      await _pump(tester, repository);

      expect(repository.bookingsIds, <String>['p1']);
      expect(find.text('Esentai City · 84'), findsOneWidget);
      expect(find.text('Предстоящие · 3'), findsOneWidget);
      expect(find.text('Прошедшие'), findsOneWidget);
      // The months are in the source's year, so they have no year suffix.
      expect(find.text('ОКТЯБРЬ'), findsOneWidget);
      expect(find.text('НОЯБРЬ'), findsOneWidget);
      // Nobody checks in on the source's today (22 October): Tuesday
      // 20 October and Tuesday 3 November show their weekday.
      expect(find.text('СЕГ'), findsNothing);
      expect(find.text('ВТ'), findsNWidgets(2));
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
      expect(find.text('Живёт'), findsOneWidget);
      expect(find.text('Марат Ильясов'), findsOneWidget);
      expect(find.text('Напрямую'), findsOneWidget);
      expect(find.text('Договор не создан'), findsOneWidget);
      expect(find.text('Олег Беляев'), findsOneWidget);
      expect(find.text('Подтверждено'), findsOneWidget);
      expect(find.text('Ксения Ли'), findsNothing);
      // The November header follows the October bookings.
      expect(
        tester.getTopLeft(find.text('НОЯБРЬ')).dy,
        greaterThan(tester.getTopLeft(find.text('Марат Ильясов')).dy),
      );
    });

    testWidgets('a check-in on the source\'s today is marked «СЕГ»', (
      WidgetTester tester,
    ) async {
      // Айжан checks in on Tuesday 20 October, the source's today here;
      // Олег's Tuesday 3 November keeps its weekday.
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..bookingsResult = Right<Failure, PropertyBookingsEntity>(
              testPropertyBookings(receivedAt: DateTime(2026, 10, 20, 9)),
            );

      await _pump(tester, repository);

      expect(find.text('СЕГ'), findsOneWidget);
      expect(find.text('ВТ'), findsOneWidget);
    });

    testWidgets('a month of another year than the source\'s has its year', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..bookingsResult = Right<Failure, PropertyBookingsEntity>(
              testPropertyBookings(receivedAt: DateTime(2025, 12, 30, 9)),
            );

      await _pump(tester, repository);

      expect(find.text('ОКТЯБРЬ 2026'), findsOneWidget);
      expect(find.text('НОЯБРЬ 2026'), findsOneWidget);
      expect(find.text('ОКТЯБРЬ'), findsNothing);
    });

    testWidgets('«Прошедшие» shows the past bookings', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakePropertyManagementRepository());

      await tester.tap(find.text('Прошедшие'));
      await tester.pumpAndSettle();

      expect(find.text('Ксения Ли'), findsOneWidget);
      expect(find.text('Отменено'), findsOneWidget);
      expect(find.text('Ерлан Жумабеков'), findsOneWidget);
      expect(find.text('Завершено'), findsOneWidget);
      expect(find.text('Айжан Сарсенова'), findsNothing);
      expect(find.text('Предстоящие · 3'), findsOneWidget);
    });

    testWidgets('an empty period says there are no bookings', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..bookingsResult = Right<Failure, PropertyBookingsEntity>(
              _withoutBookings(),
            );

      await _pump(tester, repository);

      expect(find.text('Предстоящие · 0'), findsOneWidget);
      expect(find.text('Предстоящих броней нет'), findsOneWidget);

      await tester.tap(find.text('Прошедшие'));
      await tester.pumpAndSettle();

      expect(find.text('Прошедших броней нет'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that loads again', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..bookingsResult = const Left<Failure, PropertyBookingsEntity>(
              ConnectionFailure(),
            );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить брони'), findsOneWidget);
      expect(find.text(const ConnectionFailure().userMessage), findsOneWidget);

      repository.bookingsResult = Right<Failure, PropertyBookingsEntity>(
        testPropertyBookings(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.bookingsIds, <String>['p1', 'p1']);
      expect(find.text('Не удалось загрузить брони'), findsNothing);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });

    testWidgets('a row opens its booking and reloads on return', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(find.text('Олег Беляев'));
      await tester.pumpAndSettle();
      expect(_location(router), '/bookings/b-confirmed');

      router.pop();
      await tester.pumpAndSettle();

      expect(repository.bookingsIds, <String>['p1', 'p1']);
      expect(find.text('Олег Беляев'), findsOneWidget);
    });

    testWidgets('a failed reload keeps the list and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      final GoRouter router = await _pump(tester, repository);
      await tester.tap(find.text('Олег Беляев'));
      await tester.pumpAndSettle();
      repository.bookingsResult = const Left<Failure, PropertyBookingsEntity>(
        TimeoutFailure(),
      );

      router.pop();
      await tester.pumpAndSettle();

      expect(find.text(const TimeoutFailure().userMessage), findsOneWidget);
      expect(find.text('Не удалось загрузить брони'), findsNothing);
      expect(find.text('Олег Беляев'), findsOneWidget);
    });

    testWidgets('«Добавить бронь» opens a new booking', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.text('Добавить бронь'));
      await tester.pumpAndSettle();

      expect(_location(router), AppRoutes.newBooking.path);
    });

    testWidgets('«Обзор» returns to the property', (WidgetTester tester) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.text('Обзор'));
      await tester.pumpAndSettle();

      expect(_location(router), _propertyLocation);
      expect(find.byType(PropertyBookingsScreen), findsNothing);
    });

    testWidgets('«Настройки» replaces the tab with the settings', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.text('Настройки'));
      await tester.pumpAndSettle();
      expect(_location(router), '$_propertyLocation/settings');
      expect(find.byType(PropertyBookingsScreen), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(_location(router), _propertyLocation);
    });
  });
}
