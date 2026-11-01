import 'dart:async';

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
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_detail_bloc/property_detail_bloc.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_ready_screen.dart';

import '../../../../helpers/fake_properties_repository.dart';

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

/// [PropertyReadyScreen] of [propertyId] at its own route, and the routes
/// it opens.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertiesRepository repository, {
  String propertyId = 'p2',
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    initialLocation: '/properties/$propertyId/${AppRoutes.propertyReady.path}',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.today.name,
        path: AppRoutes.today.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
      GoRoute(
        name: AppRoutes.property.name,
        path: AppRoutes.property.path,
        builder: (_, GoRouterState state) => _destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.propertyReady.name,
            path: AppRoutes.propertyReady.path,
            builder: (_, GoRouterState state) {
              final String id =
                  state.pathParameters[AppRoutes.propertyIdParam]!;
              return BlocProvider<PropertyDetailBloc>(
                create: (_) => PropertyDetailBloc(
                  getProperty: GetPropertyUsecase(repository),
                  setFavorite: SetPropertyFavoriteUsecase(repository),
                )..add(PropertyDetailRequested(id)),
                child: PropertyReadyScreen(propertyId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.calendar.name,
        path: AppRoutes.calendar.path,
        builder: (_, GoRouterState state) => _destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.channels.name,
            path: AppRoutes.channels.path,
            builder: (_, GoRouterState state) => _destination(state),
          ),
        ],
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('PropertyReadyScreen', () {
    testWidgets('shows a skeleton until the property loads', (
      WidgetTester tester,
    ) async {
      final Completer<void> gate = Completer<void>();
      final FakePropertiesRepository repository = FakePropertiesRepository()
        ..propertyGate = gate;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Квартира добавлена'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Квартира добавлена'), findsOneWidget);
    });

    testWidgets('confirms the property with its price and channels', (
      WidgetTester tester,
    ) async {
      final FakePropertiesRepository repository = FakePropertiesRepository();

      await _pump(tester, repository);

      expect(repository.propertyIds, <String>['p2']);
      expect(find.text('Квартира добавлена'), findsOneWidget);
      expect(
        find.text('Mega Towers · квартира 126\nготова принимать бронирования'),
        findsOneWidget,
      );
      expect(find.text('Mega Towers · 126'), findsOneWidget);
      expect(
        find.text('Алматы · ${MoneyFormatter.tenge(32000)} за ночь'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Airbnb уже подключён. Добавьте Booking.com, Krisha, '
          'если используете эти площадки.',
        ),
        findsOneWidget,
      );
      expect(find.text('Подключён'), findsOneWidget);
      expect(find.text('Подключить'), findsNWidgets(2));
    });

    testWidgets('a property on two channels shows both as connected', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakePropertiesRepository(), propertyId: 'p1');

      expect(find.text('Подключён'), findsNWidgets(2));
      expect(find.text('Подключить'), findsOneWidget);
    });

    testWidgets('a property without channels asks to connect them', (
      WidgetTester tester,
    ) async {
      final PropertyEntity base = testProperties()[1];
      final FakePropertiesRepository repository = FakePropertiesRepository()
        ..propertiesResult = Right<Failure, List<PropertyEntity>>(
          <PropertyEntity>[
            PropertyEntity(
              id: base.id,
              name: base.name,
              unit: base.unit,
              city: base.city,
              address: base.address,
              rooms: base.rooms,
              areaSqm: 0,
              maxGuests: base.maxGuests,
              pricePerNight: base.pricePerNight,
              imageUrls: base.imageUrls,
              channelNames: const <String>[],
              syncedAt: base.syncedAt,
              availability: base.availability,
              isFavorite: false,
              receivedAt: base.receivedAt,
            ),
          ],
        );

      await _pump(tester, repository);

      expect(
        find.text('Подключите площадки, чтобы брони попали в общий календарь.'),
        findsOneWidget,
      );
      expect(find.text('Подключён'), findsNothing);
      expect(find.text('Подключить'), findsNWidgets(3));
    });

    testWidgets('a failed load offers a retry', (WidgetTester tester) async {
      final FakePropertiesRepository repository = FakePropertiesRepository()
        ..propertiesResult = const Left<Failure, List<PropertyEntity>>(
          ConnectionFailure(),
        );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить квартиру'), findsOneWidget);

      repository.propertiesResult = Right<Failure, List<PropertyEntity>>(
        testProperties(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.propertyIds, <String>['p2', 'p2']);
      expect(find.text('Квартира добавлена'), findsOneWidget);
    });

    testWidgets('«Подключить» opens the channels', (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, FakePropertiesRepository());

      await _tapVisible(tester, find.text('Подключить').first);

      expect(_location(router), '/calendar/channels');
    });

    testWidgets('«На главную» goes to today', (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, FakePropertiesRepository());

      await tester.tap(find.text('На главную'));
      await tester.pumpAndSettle();

      expect(_location(router), AppRoutes.today.path);
      expect(find.byType(PropertyReadyScreen), findsNothing);
    });

    testWidgets('«Открыть объект» goes to the property', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(tester, FakePropertiesRepository());

      await tester.tap(find.text('Открыть объект'));
      await tester.pumpAndSettle();

      expect(_location(router), '/properties/p2');
      expect(find.byType(PropertyReadyScreen), findsNothing);
    });
  });
}
