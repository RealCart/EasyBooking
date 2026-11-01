import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_status_badge.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_detail_bloc/booking_detail_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/screens/booking_screen.dart';

import '../../../../helpers/fake_bookings_repository.dart';

/// [BookingScreen] at `/bookings/b1` in a small GoRouter: `/today`, the
/// property, and the contract only show a text.
final class _Harness {
  _Harness(this.tester, this.router, this.repository);

  final WidgetTester tester;
  final GoRouter router;
  final FakeBookingsRepository repository;

  static Future<_Harness> pump(
    WidgetTester tester, {
    void Function(FakeBookingsRepository)? arrange,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeBookingsRepository repository = FakeBookingsRepository();
    arrange?.call(repository);

    final GoRouter router = GoRouter(
      initialLocation: '/bookings/b1',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.today.name,
          path: AppRoutes.today.path,
          builder: (_, _) => const Scaffold(body: Text('Today page')),
        ),
        GoRoute(
          name: AppRoutes.booking.name,
          path: AppRoutes.booking.path,
          // The provider owns the BLoC and closes it with the route.
          builder: (_, GoRouterState state) {
            final String id = state.pathParameters[AppRoutes.bookingIdParam]!;
            return BlocProvider<BookingDetailBloc>(
              create: (_) => BookingDetailBloc(
                getBooking: GetBookingUsecase(repository),
                cancelBooking: CancelBookingUsecase(repository),
              )..add(BookingDetailRequested(id)),
              child: BookingScreen(bookingId: id),
            );
          },
        ),
        GoRoute(
          name: AppRoutes.property.name,
          path: AppRoutes.property.path,
          builder: (_, GoRouterState state) => Scaffold(
            body: Text(
              'Property ${state.pathParameters[AppRoutes.propertyIdParam]}',
            ),
          ),
        ),
        GoRoute(
          name: AppRoutes.contract.name,
          path: AppRoutes.contract.path,
          builder: (_, GoRouterState state) => Scaffold(
            body: Text(
              'Contract ${state.pathParameters[AppRoutes.contractIdParam]}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    if (settle) {
      await tester.pumpAndSettle();
    }
    return _Harness(tester, router, repository);
  }

  String get location => router.state.uri.path;

  Finder get actions => find.bySemanticsLabel('Действия с бронью');

  String get badgeLabel {
    return tester.widget<AppStatusBadge>(find.byType(AppStatusBadge)).label;
  }

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// Opens «•••» and picks «Отменить бронь»; the dialog stays open.
  Future<void> openCancelDialog() async {
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить бронь'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('shows a skeleton, then the booking', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      settle: false,
      arrange: (FakeBookingsRepository repository) =>
          repository.holdBooking = true,
    );
    await tester.pump();

    expect(find.text('Бронирование'), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);
    expect(harness.actions, findsNothing);
    expect(harness.repository.bookingIds, <String>['b1']);

    harness.repository.heldBooking.single.complete(
      Right<Failure, BookingEntity>(testBooking(comment: 'Ключи у консьержа')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppSkeleton), findsNothing);
    expect(harness.badgeLabel, 'Подтверждено');
    expect(find.text('Airbnb · HM73P2'), findsOneWidget);
    expect(find.text('Айжан Сарсенова'), findsOneWidget);
    expect(find.text('28–31 октября · 3 ночи · 2 гостя'), findsOneWidget);
    expect(find.text('Esentai City · 84'), findsOneWidget);
    expect(find.text('Заезд 14:00 · выезд 12:00'), findsOneWidget);
    expect(
      find.text('${MoneyFormatter.tenge(127500)} · оплачено'),
      findsOneWidget,
    );
    expect(
      find.text('${MoneyFormatter.tenge(50000)} · не внесён'),
      findsOneWidget,
    );
    expect(find.text('+7 701 245 18 92'), findsOneWidget);
    expect(find.text('Ключи у консьержа'), findsOneWidget);
    expect(find.text('Договор подписан'), findsOneWidget);
    expect(harness.actions, findsOneWidget);
  });

  testWidgets('each status has its badge', (WidgetTester tester) async {
    const Map<BookingStatus, String> labels = <BookingStatus, String>{
      BookingStatus.pending: 'Ожидает оплаты',
      BookingStatus.confirmed: 'Подтверждено',
      BookingStatus.checkedIn: 'Живёт',
      BookingStatus.completed: 'Завершено',
      BookingStatus.cancelled: 'Отменено',
    };
    for (final MapEntry<BookingStatus, String> entry in labels.entries) {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeBookingsRepository repository) =>
            repository.bookingResult = Right<Failure, BookingEntity>(
              testBooking(status: entry.key),
            ),
      );

      expect(harness.badgeLabel, entry.value, reason: entry.key.name);
      expect(find.text(entry.value), findsOneWidget, reason: entry.key.name);
      // Only an active booking can be cancelled from the menu.
      expect(
        harness.actions,
        entry.key.isCancellable ? findsOneWidget : findsNothing,
        reason: entry.key.name,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('an unknown booking says it was not found, without retry', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = const Left<Failure, BookingEntity>(
            ServerFailure(statusCode: 404),
          ),
    );

    expect(find.text('Бронь не найдена'), findsOneWidget);
    expect(find.text('Повторить'), findsNothing);
    expect(find.text('Связаться'), findsNothing);
  });

  testWidgets('another failure offers a retry that loads the booking', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = const Left<Failure, BookingEntity>(
            ConnectionFailure(),
          ),
    );

    expect(find.text('Не удалось загрузить бронь'), findsOneWidget);
    expect(find.text('Нет подключения к интернету'), findsOneWidget);

    harness.repository.bookingResult = Right<Failure, BookingEntity>(
      testBooking(),
    );
    await harness.tapText('Повторить');

    expect(harness.repository.bookingIds, <String>['b1', 'b1']);
    expect(find.text('Айжан Сарсенова'), findsOneWidget);
  });

  testWidgets('the apartment row opens the property', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.tapText('Esentai City · 84');

    expect(harness.location, '/properties/p1');
    expect(find.text('Property p1'), findsOneWidget);

    harness.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Айжан Сарсенова'), findsOneWidget);
  });

  testWidgets('«Открыть» opens the contract', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.tapText('Открыть');

    expect(harness.location, '/contracts/eb-1048');
    expect(find.text('Contract eb-1048'), findsOneWidget);
  });

  testWidgets('contract times are relative to the source time', (
    WidgetTester tester,
  ) async {
    // The source answered at 09:41 on 22 October.
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = Right<Failure, BookingEntity>(
            testBooking(
              contract: BookingContractEntity(
                id: 'eb-1052',
                status: BookingContractStatus.awaitingSignature,
                sentAt: DateTime(2026, 10, 21, 18, 10),
              ),
            ),
          ),
    );

    expect(find.text('Отправлен вчера, 18:10'), findsOneWidget);
  });

  testWidgets('a signed contract tells when it was signed', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = Right<Failure, BookingEntity>(
            testBooking(
              contract: BookingContractEntity(
                id: 'eb-1048',
                status: BookingContractStatus.signed,
                sentAt: DateTime(2026, 10, 22, 8, 30),
                signedAt: DateTime(2026, 10, 22, 9, 5),
              ),
            ),
          ),
    );

    expect(find.text('Подписан сегодня, 09:05'), findsOneWidget);
  });

  testWidgets('a contract without an id cannot be opened', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = Right<Failure, BookingEntity>(
            testBooking(
              contract: const BookingContractEntity(
                status: BookingContractStatus.draft,
              ),
            ),
          ),
    );

    expect(find.text('Договор не отправлен'), findsOneWidget);
    expect(find.text('Открыть'), findsNothing);
  });

  testWidgets('a booking without a contract says so', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.bookingResult = Right<Failure, BookingEntity>(
            testBooking(contract: null),
          ),
    );

    expect(find.text('Договор не создан'), findsOneWidget);
    expect(find.text('Открыть'), findsNothing);
  });

  testWidgets('«Отменить бронь» confirmed cancels the booking', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.openCancelDialog();
    expect(find.text('Отменить бронь?'), findsOneWidget);
    expect(harness.repository.cancelIds, isEmpty);

    await tester.tap(find.text('Отменить бронь'));
    await tester.pump();
    await tester.pump();

    expect(harness.repository.cancelIds, <String>['b1']);
    expect(find.text('Бронь отменена'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(harness.badgeLabel, 'Отменено');
    expect(harness.actions, findsNothing);
  });

  testWidgets('«Не отменять» keeps the booking', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.openCancelDialog();
    await tester.tap(find.text('Не отменять'));
    await tester.pumpAndSettle();

    expect(find.text('Отменить бронь?'), findsNothing);
    expect(harness.repository.cancelIds, isEmpty);
    expect(harness.badgeLabel, 'Подтверждено');
  });

  testWidgets('a failed cancel shows its message', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.cancelResult = const Left<Failure, BookingEntity>(
            ValidationFailure(code: BookingErrorCodes.notCancellable),
          ),
    );

    await harness.openCancelDialog();
    await tester.tap(find.text('Отменить бронь'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Эту бронь уже нельзя отменить'), findsOneWidget);
    expect(find.text('Бронь отменена'), findsNothing);
    expect(harness.badgeLabel, 'Подтверждено');
  });

  testWidgets('the menu is disabled while a cancel runs', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.holdCancel = true,
    );
    await harness.openCancelDialog();
    await tester.tap(find.text('Отменить бронь'));
    await tester.pumpAndSettle();

    await tester.tap(harness.actions);
    await tester.pumpAndSettle();
    expect(find.text('Даты освободятся во всех каналах'), findsNothing);

    harness.repository.heldCancel.single.complete(
      Right<Failure, BookingEntity>(
        testBooking(status: BookingStatus.cancelled),
      ),
    );
    await tester.pumpAndSettle();
    expect(harness.badgeLabel, 'Отменено');
    expect(harness.repository.cancelIds, <String>['b1']);
  });

  testWidgets('«Связаться» shows the guest phone', (WidgetTester tester) async {
    await _Harness.pump(tester);

    await tester.tap(find.text('Связаться'));
    await tester.pump();

    expect(find.text('Телефон гостя: +7 701 245 18 92'), findsOneWidget);
  });

  testWidgets('back without history goes to today', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(harness.location, AppRoutes.today.path);
  });
}
