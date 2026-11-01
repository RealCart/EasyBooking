import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:easy_booking/features/notifications/presentation/bloc/notifications_bloc/notifications_bloc.dart';
import 'package:easy_booking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:easy_booking/features/notifications/presentation/widgets/notification_row.dart';

import '../../../../helpers/fake_notifications_repository.dart';
import '../../../../helpers/router_harness.dart';

final Finder _unreadDot = find.byKey(const ValueKey<String>('unread-dot'));

/// Pumps the screen under its own [NotificationsBloc] over [repository],
/// started as `wrappedRoute` does.
Future<void> _pumpScreen(
  WidgetTester tester,
  FakeNotificationsRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<NotificationsBloc>(
        create: (_) => NotificationsBloc(
          getNotifications: GetNotificationsUsecase(repository),
          markNotificationRead: MarkNotificationReadUsecase(repository),
          markAllNotificationsRead: MarkAllNotificationsReadUsecase(repository),
        )..add(const NotificationsRequested()),
        child: const NotificationsScreen(),
      ),
    ),
  );
}

void main() {
  group('NotificationsScreen states', () {
    testWidgets('the first load shows a skeleton', (WidgetTester tester) async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()..holdFeed = true;

      await _pumpScreen(tester, repository);
      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.byType(NotificationRow), findsNothing);
    });

    testWidgets('the feed is grouped by day with relative times', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, FakeNotificationsRepository());
      await tester.pumpAndSettle();

      expect(find.text('Сегодня'), findsOneWidget);
      expect(find.text('Вчера'), findsOneWidget);
      expect(find.byType(NotificationRow), findsNWidgets(3));
      expect(find.text('21 мин'), findsOneWidget);
      expect(find.text('1 ч'), findsOneWidget);
      expect(find.text('18:42'), findsOneWidget);
      expect(_unreadDot, findsOneWidget);
    });

    testWidgets('a chip filters the feed', (WidgetTester tester) async {
      await _pumpScreen(tester, FakeNotificationsRepository());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Договоры'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationRow), findsOneWidget);
      expect(find.text('Договор подписан'), findsOneWidget);
      expect(find.text('Вчера'), findsNothing);
    });

    testWidgets('an empty filter explains itself', (WidgetTester tester) async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()
            ..feedResult = Right<Failure, NotificationFeedEntity>(
              NotificationFeedEntity(
                notifications: const <NotificationEntity>[],
                receivedAt: notificationsTestNow,
              ),
            );
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Важные'));
      await tester.pumpAndSettle();

      expect(find.text('Важных уведомлений нет'), findsOneWidget);
    });

    testWidgets('«Прочитать» removes the unread dot and then disables', (
      WidgetTester tester,
    ) async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository();
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Прочитать'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Прочитать'));
      await tester.pumpAndSettle();

      expect(repository.markAllReadCount, 1);
      expect(_unreadDot, findsNothing);
    });

    testWidgets('a failed «Прочитать» shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()
            ..markAllReadResult = const Left<Failure, void>(
              ConnectionFailure(),
            );
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Прочитать'));
      await tester.pumpAndSettle();

      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(_unreadDot, findsOneWidget);
    });

    testWidgets('a failed load offers a retry that shows the feed', (
      WidgetTester tester,
    ) async {
      final FakeNotificationsRepository repository =
          FakeNotificationsRepository()
            ..feedResult = const Left<Failure, NotificationFeedEntity>(
              ConnectionFailure(),
            );
      await _pumpScreen(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('Не удалось загрузить уведомления'), findsOneWidget);

      repository.feedResult = Right<Failure, NotificationFeedEntity>(
        testNotificationFeed(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationRow), findsNWidgets(3));
    });
  });

  group('NotificationsScreen navigation', () {
    Future<RouterHarness> openNotifications(WidgetTester tester) async {
      final RouterHarness harness = await RouterHarness.pump(tester);
      harness.router.push('/notifications');
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets('the home bell opens the feed of the mock source', (
      WidgetTester tester,
    ) async {
      await openNotifications(tester);

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('Конфликт бронирований'), findsOneWidget);
      expect(find.text('2 мин'), findsOneWidget);
    });

    testWidgets('«Разрешить конфликт» opens the calendar conflict', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await openNotifications(tester);

      await tester.tap(find.text('Разрешить конфликт'));
      await tester.pumpAndSettle();

      expect(harness.location, '/calendar-conflicts/conflict-esentai-84');
    });

    testWidgets('a failed sync opens the property settings, now read', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await openNotifications(tester);

      await tester.tap(find.text('Airbnb не обновился'));
      await tester.pumpAndSettle();

      expect(harness.location, '/properties/esentai-city-84/settings');
      harness.router.pop();
      await tester.pumpAndSettle();
      expect(_unreadDot, findsNothing);
    });

    testWidgets('back returns to today', (WidgetTester tester) async {
      final RouterHarness harness = await openNotifications(tester);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
    });
  });
}
