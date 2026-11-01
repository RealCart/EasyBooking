import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guest_detail_bloc/guest_detail_bloc.dart';
import 'package:easy_booking/features/guests/presentation/screens/guest_screen.dart';

import '../../../../helpers/fake_guests_repository.dart';

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

/// [screen] at `/` and the contract and booking routes it opens.
GoRouter _router(RouteBase screenRoute) {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      screenRoute,
      GoRoute(
        name: AppRoutes.contract.name,
        path: AppRoutes.contract.path,
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
  return router;
}

/// Pumps [GuestScreen] for guest `g1` under its own [BlocProvider] over
/// [repository].
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeGuestsRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = _router(
    GoRoute(
      name: AppRoutes.guest.name,
      path: '/',
      builder: (_, _) => BlocProvider<GuestDetailBloc>(
        create: (_) => GuestDetailBloc(
          getGuest: GetGuestUsecase(repository),
          createContract: CreateGuestContractUsecase(repository),
        )..add(const GuestDetailRequested('g1')),
        child: const GuestScreen(guestId: 'g1'),
      ),
    ),
  );
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

final Finder _createButton = find.widgetWithText(
  FilledButton,
  'Создать договор',
);

void main() {
  group('GuestScreen', () {
    testWidgets('shows a skeleton and no actions while loading', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..holdGuest = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Создать договор'), findsNothing);
      expect(find.bySemanticsLabel('Ещё'), findsNothing);

      repository.heldGuest.single.complete(
        Right<Failure, GuestEntity>(testGuest()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });

    testWidgets('shows the guest, the document, stays, and contracts', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();

      await _pump(tester, repository);

      expect(repository.guestIds, <String>['g1']);
      expect(find.text('Гость'), findsOneWidget);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
      expect(find.text('+7 701 245 18 92'), findsOneWidget);
      expect(find.text('Удостоверение личности'), findsOneWidget);
      expect(find.text('Проверено 18 октября'), findsOneWidget);
      expect(find.text('Esentai City · 84'), findsOneWidget);
      expect(find.text('22–25 октября · 3 ночи'), findsOneWidget);
      expect(find.text('Скоро'), findsOneWidget);
      expect(find.text('Mega Towers · 126'), findsOneWidget);
      expect(find.text('№ EB-1048'), findsOneWidget);
      expect(find.text('Подписан 18 октября'), findsOneWidget);
      expect(_createButton, findsOneWidget);
    });

    testWidgets('a guest without stays or contracts says so', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..guestResult = Right<Failure, GuestEntity>(
          testGuest(
            stays: const <GuestStayEntity>[],
            contracts: const <GuestContractEntity>[],
          ),
        );

      await _pump(tester, repository);

      expect(find.text('Проживаний пока нет'), findsOneWidget);
      expect(find.text('Договоров пока нет'), findsOneWidget);
    });

    testWidgets('an unknown guest says it was not found, without a retry', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..guestResult = const Left<Failure, GuestEntity>(
          ServerFailure(statusCode: 404),
        );

      await _pump(tester, repository);

      expect(find.text('Гость не найден'), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
      expect(find.text('Создать договор'), findsNothing);
    });

    testWidgets('another failure offers a retry that loads the guest', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..guestResult = const Left<Failure, GuestEntity>(ConnectionFailure());

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить гостя'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);

      repository.guestResult = Right<Failure, GuestEntity>(testGuest());
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.guestIds, <String>['g1', 'g1']);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });

    testWidgets('«Создать договор» opens the created contract', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_createButton);
      await tester.pumpAndSettle();

      expect(repository.createContractIds, <String>['g1']);
      expect(_location(router), '/contracts/draft-g1');
    });

    testWidgets('a second «Создать договор» after returning opens it again', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GoRouter router = await _pump(tester, repository);
      await tester.tap(_createButton);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(_location(router), '/');

      await tester.tap(_createButton);
      await tester.pumpAndSettle();

      expect(repository.createContractIds, <String>['g1', 'g1']);
      expect(_location(router), '/contracts/draft-g1');
    });

    testWidgets('the button shows progress and ignores taps while creating', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..holdCreateContract = true;
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_createButton);
      await tester.pump();

      final Finder button = find.byType(FilledButton);
      expect(
        find.descendant(
          of: button,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(repository.createContractIds, <String>['g1']);

      repository.heldCreateContract.single.complete(
        const Right<Failure, String>('draft-g1'),
      );
      await tester.pumpAndSettle();
      expect(_location(router), '/contracts/draft-g1');
    });

    testWidgets('a failed creation shows a snackbar and stays', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..createContractResult = const Left<Failure, String>(
          ConnectionFailure(),
        );
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_createButton);
      await tester.pumpAndSettle();

      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(_location(router), '/');
      expect(_createButton, findsOneWidget);
    });

    testWidgets('a stay row opens its booking', (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, FakeGuestsRepository());

      await _tapVisible(tester, find.text('Esentai City · 84'));

      expect(_location(router), '/bookings/b1');
    });

    testWidgets('a contract row opens the contract', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(tester, FakeGuestsRepository());

      await _tapVisible(tester, find.text('№ EB-1048'));

      expect(_location(router), '/contracts/c1');
    });

    testWidgets('wrappedRoute builds its BLoC from AppDependencies and loads', (
      WidgetTester tester,
    ) async {
      _usePhoneSize(tester);
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GetIt getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      getIt
        ..registerLazySingleton<GetGuestUsecase>(
          () => GetGuestUsecase(repository),
        )
        ..registerLazySingleton<CreateGuestContractUsecase>(
          () => CreateGuestContractUsecase(repository),
        );
      final GoRouter router = _router(
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.guest.name,
          path: '/guests/:${AppRoutes.guestIdParam}',
          wrappedBuilder: (_, GoRouterState state) => GuestScreen(
            guestId: state.pathParameters[AppRoutes.guestIdParam]!,
          ),
        ),
      );
      router.go('/guests/g7');

      await tester.pumpWidget(
        AppDependenciesProvider(
          dependencies: AppDependencies.fromContainer(getIt),
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.guestIds, <String>['g7']);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);

      await tester.tap(_createButton);
      await tester.pumpAndSettle();
      expect(repository.createContractIds, <String>['g1']);
    });
  });
}
