import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';
import 'package:easy_booking/features/calendar/presentation/bloc/channels_bloc/channels_bloc.dart';
import 'package:easy_booking/features/calendar/presentation/screens/channels_screen.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/channel_tile.dart';

import '../../../../helpers/fake_channels_repository.dart';

/// The 430 × 932 phone of the design.
void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [ChannelsScreen] at `/` under its own [BlocProvider] over
/// [repository], with the channel route it opens. Returns the router and
/// the BLoC.
Future<(GoRouter, ChannelsBloc)> _pump(
  WidgetTester tester,
  FakeChannelsRepository repository, {
  bool settle = true,
}) async {
  _usePhoneSize(tester);
  late ChannelsBloc bloc;
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.channels.name,
        path: '/',
        builder: (_, _) => BlocProvider<ChannelsBloc>(
          create: (_) =>
              bloc = ChannelsBloc(getChannels: GetChannelsUsecase(repository))
                ..add(const ChannelsRequested()),
          child: const ChannelsScreen(),
        ),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.channel.name,
            path: AppRoutes.channel.path,
            builder: (_, GoRouterState state) =>
                Scaffold(body: Text('route:${state.uri}')),
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
  return (router, bloc);
}

String _location(GoRouter router) => router.state.uri.toString();

/// The tile of channel [name].
Finder _tile(String name) {
  return find.ancestor(of: find.text(name), matching: find.byType(ChannelTile));
}

void main() {
  group('ChannelsScreen', () {
    testWidgets('shows a skeleton while the channels load', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..holdChannels = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.byType(ChannelTile), findsNothing);
    });

    testWidgets('lists every channel with its status and the last check', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeChannelsRepository());

      expect(find.text('Каналы'), findsOneWidget);
      expect(find.text('3 подключения · 2 объекта'), findsOneWidget);
      // The check was on the source's today, so only its time is shown.
      expect(find.text('Последняя проверка 09:38'), findsOneWidget);
      expect(find.text('2 объекта · обновлено 09:38'), findsOneWidget);
      for (final (String name, String status) in <(String, String)>[
        ('Booking.com', 'Подключён'),
        ('Airbnb', 'Ошибка'),
        ('Krisha', 'Настроить'),
        ('Avito', 'Отключён'),
      ]) {
        expect(
          find.descendant(of: _tile(name), matching: find.text(status)),
          findsOneWidget,
          reason: name,
        );
      }
      expect(find.text('Ручные брони · экспорт iCal'), findsOneWidget);
      expect(find.text('Календарь не синхронизируется'), findsOneWidget);
    });

    testWidgets('a failing channel gets a callout that opens it', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      final (GoRouter router, _) = await _pump(tester, repository);

      expect(find.text('Airbnb не обновился'), findsOneWidget);
      expect(find.text('Mega Towers · проверьте ссылку iCal'), findsOneWidget);

      await tester.ensureVisible(find.text('Исправить'));
      await tester.tap(find.text('Исправить'));
      await tester.pumpAndSettle();

      expect(_location(router), '/airbnb');
    });

    testWidgets('a tile opens its channel and the list reloads after', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      final (GoRouter router, _) = await _pump(tester, repository);

      await tester.tap(find.text('Booking.com'));
      await tester.pumpAndSettle();

      expect(_location(router), '/booking-com');

      router.pop();
      await tester.pumpAndSettle();

      expect(_location(router), '/');
      expect(repository.channelsCount, 2);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..channelsResult = const Left<Failure, ChannelsOverviewEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить каналы'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);

      repository.channelsResult = Right<Failure, ChannelsOverviewEntity>(
        testChannelsOverview(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить каналы'), findsNothing);
      expect(find.byType(ChannelTile), findsNWidgets(4));
    });

    testWidgets('a failed reload keeps the channels and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeChannelsRepository repository = FakeChannelsRepository();
      final (_, ChannelsBloc bloc) = await _pump(tester, repository);
      repository.channelsResult = const Left<Failure, ChannelsOverviewEntity>(
        TimeoutFailure(),
      );

      bloc.add(const ChannelsRequested());
      await tester.pumpAndSettle();

      expect(find.byType(ChannelTile), findsNWidgets(4));
      expect(find.text('Не удалось загрузить каналы'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Сервер долго не отвечает. Попробуйте ещё раз'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('no channels says so', (WidgetTester tester) async {
      final FakeChannelsRepository repository = FakeChannelsRepository()
        ..channelsResult = Right<Failure, ChannelsOverviewEntity>(
          ChannelsOverviewEntity(
            channels: const <ChannelEntity>[],
            checkedAt: channelsTestCheckedAt,
            receivedAt: channelsTestReceivedAt,
          ),
        );

      await _pump(tester, repository);

      expect(find.text('Каналы не подключены'), findsOneWidget);
    });
  });
}
