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
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/property_settings_bloc/property_settings_bloc.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_settings_screen.dart';

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

/// The property at `/properties/p1` with the settings screen on top of it,
/// and the routes the screen opens.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertyManagementRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = GoRouter(
    initialLocation: '$_propertyLocation/${AppRoutes.propertySettings.path}',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.property.name,
        path: AppRoutes.property.path,
        builder: (_, GoRouterState state) => _destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.propertySettings.name,
            path: AppRoutes.propertySettings.path,
            builder: (_, GoRouterState state) =>
                BlocProvider<PropertySettingsBloc>(
                  create: (_) => PropertySettingsBloc(
                    getSettings: GetPropertySettingsUsecase(repository),
                    saveSettings: SavePropertySettingsUsecase(repository),
                  )..add(const PropertySettingsRequested('p1')),
                  child: const PropertySettingsScreen(propertyId: 'p1'),
                ),
          ),
          GoRoute(
            name: AppRoutes.propertyBookings.name,
            path: AppRoutes.propertyBookings.path,
            builder: (_, GoRouterState state) => _destination(state),
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
      GoRoute(
        name: AppRoutes.profile.name,
        path: AppRoutes.profile.path,
        builder: (_, GoRouterState state) => _destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.team.name,
            path: AppRoutes.team.path,
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

/// Scrolls the settings list back to its header.
Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, 2000));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

final Finder _saveButton = find.widgetWithText(
  FilledButton,
  'Сохранить изменения',
);

void main() {
  group('PropertySettingsScreen', () {
    testWidgets('shows a skeleton and no save button while loading', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()..holdSettings = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(_saveButton, findsNothing);

      repository.heldSettings.single.complete(
        Right<Failure, PropertySettingsEntity>(testPropertySettings()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(_saveButton, findsOneWidget);
    });

    testWidgets('shows the summary of the stored settings', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();

      await _pump(tester, repository);

      expect(repository.settingsIds, <String>['p1']);
      expect(find.text('Esentai City · 84'), findsOneWidget);
      expect(find.text('Управление объектом'), findsOneWidget);
      expect(find.text('Активен'), findsOneWidget);
      expect(find.text('Квартира · Аль-Фараби, 77/8'), findsOneWidget);
      expect(find.text('Заезд 14:00 · выезд 12:00'), findsOneWidget);
      expect(find.text('Не курить · Без вечеринок'), findsOneWidget);
      expect(find.text('Booking.com, Airbnb · одна ошибка'), findsOneWidget);
      expect(find.text('Проверить'), findsOneWidget);
    });

    testWidgets('a paused property says «Приостановлен»', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..settingsResult = Right<Failure, PropertySettingsEntity>(
              testPropertySettings(acceptsBookings: false),
            );

      await _pump(tester, repository);

      expect(find.text('Приостановлен'), findsOneWidget);
      expect(find.text('Активен'), findsNothing);
    });

    testWidgets('a failed load offers a retry that loads again', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..settingsResult = const Left<Failure, PropertySettingsEntity>(
              ConnectionFailure(),
            );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить настройки'), findsOneWidget);
      expect(_saveButton, findsNothing);

      repository.settingsResult = Right<Failure, PropertySettingsEntity>(
        testPropertySettings(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.settingsIds, <String>['p1', 'p1']);
      expect(find.text('Активен'), findsOneWidget);
    });

    testWidgets('the switch changes only locally until saved', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      await _pump(tester, repository);

      await _tapVisible(tester, find.byType(Switch));

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(find.text('Новые брони не принимаются'), findsOneWidget);
      await _scrollToTop(tester);
      expect(find.text('Активен'), findsOneWidget);
      expect(repository.saveSettingsCalls, isEmpty);
    });

    testWidgets('«Сохранить изменения» saves the switch and confirms', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      await _pump(tester, repository);
      await _tapVisible(tester, find.byType(Switch));

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(repository.saveSettingsCalls.single, (
        propertyId: 'p1',
        acceptsBookings: false,
      ));
      expect(find.text('Изменения сохранены'), findsOneWidget);
      await _scrollToTop(tester);
      expect(find.text('Приостановлен'), findsOneWidget);
    });

    testWidgets('saving an untouched switch sends the stored value', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(repository.saveSettingsCalls.single, (
        propertyId: 'p1',
        acceptsBookings: true,
      ));
    });

    testWidgets('the button is busy while saving and ignores taps', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()..holdSaveSettings = true;
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pump();
      // The label gives way to a spinner while saving.
      final Finder busyButton = find.byType(FilledButton);
      expect(_saveButton, findsNothing);
      expect(tester.widget<FilledButton>(busyButton).onPressed, isNull);
      await tester.tap(busyButton, warnIfMissed: false);
      await tester.pump();

      expect(repository.saveSettingsCalls, hasLength(1));

      repository.heldSaveSettings.single.complete(
        Right<Failure, PropertySettingsEntity>(testPropertySettings()),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);
    });

    testWidgets('a failed save shows the failure', (WidgetTester tester) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..saveSettingsResult = const Left<Failure, PropertySettingsEntity>(
              TimeoutFailure(),
            );
      await _pump(tester, repository);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.text(const TimeoutFailure().userMessage), findsOneWidget);
      expect(find.text('Изменения сохранены'), findsNothing);
    });

    testWidgets('«Каналы» opens the channels', (WidgetTester tester) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await _tapVisible(tester, find.text('Каналы'));

      expect(_location(router), '/calendar/channels');
    });

    testWidgets('«Команда» opens the team', (WidgetTester tester) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await _tapVisible(tester, find.text('Команда'));

      expect(_location(router), '/profile/team');
    });

    testWidgets('other rows and «Ещё» say it is coming soon', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await _tapVisible(tester, find.text('Фотографии'));
      expect(find.text('Скоро будет'), findsOneWidget);

      await _tapVisible(tester, find.bySemanticsLabel('Ещё'));
      expect(find.text('Скоро будет'), findsOneWidget);
      expect(_location(router), '$_propertyLocation/settings');
    });

    testWidgets('«Обзор» returns to the property', (WidgetTester tester) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.text('Обзор'));
      await tester.pumpAndSettle();

      expect(_location(router), _propertyLocation);
    });

    testWidgets('«Брони» replaces the tab with the bookings', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.text('Брони'));
      await tester.pumpAndSettle();
      expect(_location(router), '$_propertyLocation/bookings');

      router.pop();
      await tester.pumpAndSettle();
      expect(_location(router), _propertyLocation);
    });
  });
}
