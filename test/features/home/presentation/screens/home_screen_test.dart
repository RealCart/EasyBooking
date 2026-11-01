import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_arrival_card.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/home/domain/entity/home_overview_entity.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';
import 'package:easy_booking/features/home/presentation/bloc/home_bloc/home_bloc.dart';
import 'package:easy_booking/features/home/presentation/screens/home_screen.dart';

import '../../../../helpers/fake_home_repository.dart';
import '../../../../helpers/router_harness.dart';

/// Pumps the screen under its own [HomeBloc] over [repository], started as
/// `wrappedRoute` does.
Future<void> _pumpScreen(
  WidgetTester tester,
  FakeHomeRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<HomeBloc>(
        create: (_) => HomeBloc(
          getHomeOverview: GetHomeOverviewUsecase(repository),
        )..add(const HomeOverviewRequested()),
        child: const HomeScreen(),
      ),
    ),
  );
}

void main() {
  group('HomeScreen states', () {
    testWidgets('the first load shows a skeleton', (WidgetTester tester) async {
      final FakeHomeRepository repository = FakeHomeRepository()
        ..holdOverview = true;

      await _pumpScreen(tester, repository);
      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.byType(AppArrivalCard), findsNothing);
      expect(find.text('Сегодня'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry that shows the day', (
      WidgetTester tester,
    ) async {
      final FakeHomeRepository repository = FakeHomeRepository()
        ..overviewResult = const Left<Failure, HomeOverviewEntity>(
          ConnectionFailure(),
        );

      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить день'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.byType(AppArrivalCard), findsNothing);

      repository.overviewResult = Right<Failure, HomeOverviewEntity>(
        testHomeOverview(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.overviewCount, 2);
      expect(find.text('Не удалось загрузить день'), findsNothing);
      expect(find.byType(AppArrivalCard), findsOneWidget);
      expect(find.text('Заезды · 1'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the day and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeHomeRepository repository = FakeHomeRepository();
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();
      repository.overviewResult = const Left<Failure, HomeOverviewEntity>(
        ConnectionFailure(),
      );

      await tester.fling(
        find.text('Сегодня'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.overviewCount, 2);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.byType(AppArrivalCard), findsOneWidget);
    });
  });

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
      expect(find.text('Четверг, 22 октября'), findsOneWidget);
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
      expect(find.text('Мадина · 3 ночи'), findsOneWidget);
      expect(find.text('до 24 окт'), findsOneWidget);
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

      expect(harness.location, '/contracts/eb-1052');
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
