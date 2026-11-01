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
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guests_bloc/guests_bloc.dart';
import 'package:easy_booking/features/guests/presentation/screens/guests_screen.dart';

import '../../../../helpers/fake_guests_repository.dart';

/// The 430 × 932 phone of the design, so lazy lists build every row.
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

/// The routes the screen navigates to, around [screen] at `/`.
GoRouter _router(Widget Function(BuildContext context) screen) {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.guests.name,
        path: '/',
        builder: (BuildContext context, _) => screen(context),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.guest.name,
            path: AppRoutes.guest.path,
            builder: (_, GoRouterState state) => _destination(state),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.contract.name,
        path: AppRoutes.contract.path,
        builder: (_, GoRouterState state) => _destination(state),
      ),
    ],
  );
  addTearDown(router.dispose);
  return router;
}

/// Pumps [GuestsScreen] under its own [BlocProvider] over [repository].
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeGuestsRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  final GoRouter router = _router(
    (_) => BlocProvider<GuestsBloc>(
      create: (_) =>
          GuestsBloc(getDirectory: GetGuestDirectoryUsecase(repository))
            ..add(const GuestsRequested()),
      child: const GuestsScreen(),
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

/// Types [query] and waits out the search debounce.
Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(GuestsBloc.queryDebounce);
  await tester.pumpAndSettle();
}

String _location(GoRouter router) => router.state.uri.toString();

GuestDirectoryEntity _emptyDirectory({String query = ''}) {
  return testGuestDirectory(
    query: query,
    guests: const <GuestSummaryEntity>[],
    contracts: const <GuestContractEntity>[],
  );
}

void main() {
  group('GuestsScreen', () {
    testWidgets('shows a skeleton while the first load runs', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..holdDirectory = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Недавние гости'), findsNothing);

      repository.heldDirectory.single.complete(
        Right<Failure, GuestDirectoryEntity>(testGuestDirectory()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.text('Недавние гости'), findsOneWidget);
    });

    testWidgets('lists the recent guests with the total count', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();

      await _pump(tester, repository);

      expect(repository.directoryQueries, <String>['']);
      expect(find.text('Гости и договоры'), findsOneWidget);
      expect(find.text('Недавние гости'), findsOneWidget);
      expect(find.text('12 гостей'), findsOneWidget);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
      expect(find.text('Esentai City · заезд сегодня'), findsOneWidget);
      expect(find.text('Подписан'), findsOneWidget);
      expect(find.text('Арман Темирбек'), findsOneWidget);
      expect(find.text('Mega Towers · выехал вчера'), findsOneWidget);
      expect(find.text('Нет договора'), findsOneWidget);
    });

    testWidgets('an empty directory explains that there are no guests yet', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..directoryResult = Right<Failure, GuestDirectoryEntity>(
          _emptyDirectory(),
        );

      await _pump(tester, repository);
      expect(find.text('Гостей пока нет'), findsOneWidget);

      await tester.tap(find.text('Договоры'));
      await tester.pumpAndSettle();
      expect(find.text('Договоров пока нет'), findsOneWidget);
    });

    testWidgets('a failed first load offers a retry that loads the list', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository()
        ..directoryResult = const Left<Failure, GuestDirectoryEntity>(
          ConnectionFailure(),
        );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить гостей'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);

      repository.directoryResult = Right<Failure, GuestDirectoryEntity>(
        testGuestDirectory(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.directoryQueries, <String>['', '']);
      expect(find.text('Не удалось загрузить гостей'), findsNothing);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });

    testWidgets('pull-to-refresh reloads the directory', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);

      await tester.fling(
        find.text('Айжан Сарсенова'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.directoryQueries, <String>['', '']);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    });

    testWidgets('a failed refresh keeps the list and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);
      repository.directoryResult = const Left<Failure, GuestDirectoryEntity>(
        ConnectionFailure(),
      );

      await tester.fling(
        find.text('Айжан Сарсенова'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
      expect(find.text('Не удалось загрузить гостей'), findsNothing);
    });

    testWidgets('the «Договоры» tab lists the contracts and switches back', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);

      await tester.tap(find.text('Договоры'));
      await tester.pumpAndSettle();

      expect(find.text('Все договоры'), findsOneWidget);
      expect(find.text('2 договора'), findsOneWidget);
      expect(find.text('№ EB-1052'), findsOneWidget);
      expect(
        find.text('Данияр Муратов · Samal Residence · 12'),
        findsOneWidget,
      );
      expect(find.text('Ждём подпись'), findsOneWidget);
      expect(find.text('№ EB-1048'), findsOneWidget);
      expect(find.text('Недавние гости'), findsNothing);

      await tester.tap(find.text('Гости'));
      await tester.pumpAndSettle();

      expect(find.text('Недавние гости'), findsOneWidget);
      expect(find.text('№ EB-1052'), findsNothing);
      // Switching tabs is local: nothing is requested again.
      expect(repository.directoryQueries, <String>['']);
    });

    testWidgets('typing searches after the debounce and shows the results', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);

      await tester.enterText(find.byType(TextField), 'Ай');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), ' Айжан ');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repository.directoryQueries, <String>['']);

      await tester.pump(GuestsBloc.queryDebounce);
      await tester.pumpAndSettle();

      expect(repository.directoryQueries, <String>['', 'Айжан']);
      expect(find.text('Результаты поиска'), findsOneWidget);
      // While searching, the count is the number of matches.
      expect(find.text('2 гостя'), findsOneWidget);
    });

    testWidgets('a search without matches explains the empty result', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);
      repository.directoryResult = Right<Failure, GuestDirectoryEntity>(
        _emptyDirectory(query: 'zzz'),
      );

      await _search(tester, 'zzz');
      expect(find.text('Никого не нашли'), findsOneWidget);

      await tester.tap(find.text('Договоры'));
      await tester.pumpAndSettle();
      expect(find.text('Договоров не нашли'), findsOneWidget);
    });

    testWidgets('the clear button empties the field and shows recent guests', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      await _pump(tester, repository);
      expect(find.bySemanticsLabel('Очистить поиск'), findsNothing);

      await _search(tester, 'Айжан');
      expect(find.text('Результаты поиска'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Очистить поиск'));
      await tester.pump(GuestsBloc.queryDebounce);
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.bySemanticsLabel('Очистить поиск'), findsNothing);
      expect(repository.directoryQueries, <String>['', 'Айжан', '']);
      expect(find.text('Недавние гости'), findsOneWidget);
    });

    testWidgets('a guest row opens the guest and returning reloads', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(find.text('Арман Темирбек'));
      await tester.pumpAndSettle();
      expect(_location(router), '/g2');

      router.pop();
      await tester.pumpAndSettle();

      expect(_location(router), '/');
      expect(repository.directoryQueries, <String>['', '']);
    });

    testWidgets('a contract row opens the contract', (
      WidgetTester tester,
    ) async {
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(find.text('Договоры'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('№ EB-1052'));
      await tester.pumpAndSettle();

      expect(_location(router), '/contracts/c2');
    });

    testWidgets('«Добавить гостя» says it is coming soon', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeGuestsRepository());

      await tester.tap(find.bySemanticsLabel('Добавить гостя'));
      await tester.pumpAndSettle();

      expect(find.text('Скоро будет'), findsOneWidget);
    });

    testWidgets('wrappedRoute builds its BLoC from AppDependencies and loads', (
      WidgetTester tester,
    ) async {
      _usePhoneSize(tester);
      final FakeGuestsRepository repository = FakeGuestsRepository();
      final GetIt getIt = GetIt.asNewInstance();
      addTearDown(getIt.reset);
      getIt.registerLazySingleton<GetGuestDirectoryUsecase>(
        () => GetGuestDirectoryUsecase(repository),
      );
      final GoRouter router = GoRouter(
        routes: <RouteBase>[
          GoRouteExtension.wrappedRoute(
            name: AppRoutes.guests.name,
            path: '/',
            wrappedBuilder: (_, _) => const GuestsScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

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

      expect(repository.directoryQueries, <String>['']);
      expect(find.text('Айжан Сарсенова'), findsOneWidget);
    });
  });
}
