import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_create_bloc/booking_create_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/screens/new_booking_price_screen.dart';

import '../../../../helpers/fake_bookings_repository.dart';

/// [NewBookingPriceScreen] at `/bookings/new/guest` in a small GoRouter:
/// step 1 `/bookings/new` and the booking `/bookings/:bookingId` only show
/// a text.
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

    final FakeBookingsRepository repository = FakeBookingsRepository()
      ..draftResult = Right<Failure, CurrentBookingDraftEntity>(
        testCurrentDraft(testDraft()),
      );
    arrange?.call(repository);

    final GoRouter router = GoRouter(
      initialLocation: '/bookings/new/guest',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.newBooking.name,
          path: AppRoutes.newBooking.path,
          builder: (_, _) => const Scaffold(body: Text('Step 1 page')),
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.newBookingGuest.name,
              path: AppRoutes.newBookingGuest.path,
              // The provider owns the BLoC and closes it with the route.
              builder: (_, _) => BlocProvider<BookingCreateBloc>(
                create: (_) => BookingCreateBloc(
                  getDraft: GetBookingDraftUsecase(repository),
                  createBooking: CreateBookingUsecase(repository),
                )..add(const BookingCreateStarted()),
                child: const NewBookingPriceScreen(),
              ),
            ),
          ],
        ),
        GoRoute(
          name: AppRoutes.booking.name,
          path: AppRoutes.booking.path,
          builder: (_, GoRouterState state) => Scaffold(
            body: Text(
              'Booking ${state.pathParameters[AppRoutes.bookingIdParam]}',
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

  Finder field(String label) {
    return find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );
  }

  Finder get createButton => find.widgetWithText(FilledButton, 'Создать бронь');

  bool get isCreateEnabled {
    return tester.widget<FilledButton>(createButton).onPressed != null;
  }

  String text(String label) {
    return tester.widget<TextField>(field(label)).controller!.text;
  }

  Future<void> type(String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> submit() async {
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();
    await tester.pump();
  }
}

void main() {
  testWidgets('shows a skeleton, then the form prefilled from the quote', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      settle: false,
      arrange: (FakeBookingsRepository repository) =>
          repository.holdDraft = true,
    );
    await tester.pump();

    expect(find.text('Цена и источник'), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);
    expect(harness.createButton, findsNothing);

    harness.repository.heldDraft.single.complete(
      Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft(testDraft())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppSkeleton), findsNothing);
    expect(find.text('Esentai City · 28–31 октября'), findsOneWidget);
    expect(harness.text('Итого'), MoneyFormatter.group(127500));
    expect(harness.text('Депозит'), MoneyFormatter.group(50000));
    for (final String label in <String>[
      'Источник брони',
      'Напрямую',
      'Krisha',
      'Другое',
      'Комментарий для команды',
      'Создать договор после брони',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(harness.isCreateEnabled, isTrue);
  });

  testWidgets('free dates say which calendars were checked', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(tester);

    expect(find.text('Даты свободны'), findsOneWidget);
    expect(
      find.text('Проверено по Booking.com, Airbnb и локальному календарю.'),
      findsOneWidget,
    );
    expect(find.text('Изменить даты'), findsNothing);
  });

  testWidgets('taken dates disable creating and offer to change them', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
            testCurrentDraft(
              testDraft(conflictingBookingIds: <String>['booking-1042']),
            ),
          ),
    );

    expect(find.text('Даты заняты'), findsOneWidget);
    expect(harness.isCreateEnabled, isFalse);

    await harness.tapText('Изменить даты');

    expect(harness.location, AppRoutes.newBooking.path);
    expect(find.text('Step 1 page'), findsOneWidget);
    expect(harness.repository.createCalls, isEmpty);
  });

  testWidgets('the defaults create a direct booking with a contract', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.submit();
    await tester.pumpAndSettle();

    expect(harness.repository.createCalls, <CreateBookingParamsEntity>[
      const CreateBookingParamsEntity(
        draftId: 'draft-1',
        totalPrice: 127500,
        deposit: 50000,
        source: BookingSource.direct,
        createContract: true,
      ),
    ]);
    expect(harness.location, '/bookings/booking-1060');
    expect(find.text('Booking booking-1060'), findsOneWidget);
  });

  testWidgets('the edited form is sent as typed', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.type('Итого', '150 000');
    await harness.type('Депозит', '0');
    await harness.tapText('Krisha');
    await harness.type('Комментарий для команды', '  Поздний заезд  ');
    await harness.tapText('Создать договор после брони');
    await harness.submit();
    await tester.pumpAndSettle();

    expect(harness.repository.createCalls, <CreateBookingParamsEntity>[
      const CreateBookingParamsEntity(
        draftId: 'draft-1',
        totalPrice: 150000,
        deposit: 0,
        source: BookingSource.krisha,
        createContract: false,
        comment: 'Поздний заезд',
      ),
    ]);
    expect(find.text('Booking booking-1060'), findsOneWidget);
  });

  testWidgets('«Другое» is sent as the other source', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.tapText('Другое');
    await harness.submit();

    expect(harness.repository.createCalls.single.source, BookingSource.other);
  });

  testWidgets('invalid amounts show the errors and create nothing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.type('Итого', '');
    await harness.type('Депозит', 'abc');
    await harness.submit();

    expect(find.text(FormValidators.requiredMessage), findsOneWidget);
    expect(find.text(FormValidators.invalidAmountMessage), findsOneWidget);
    expect(harness.repository.createCalls, isEmpty);

    await harness.type('Итого', '0');
    await harness.type('Депозит', '0');
    await harness.submit();

    expect(find.text(FormValidators.invalidAmountMessage), findsOneWidget);
    expect(harness.repository.createCalls, isEmpty);
    expect(harness.location, '/bookings/new/guest');
  });

  testWidgets('a server field error shows under its field', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.createResult = const Left<Failure, String>(
            ValidationFailure(
              fieldErrors: <String, String>{
                BookingFields.deposit: BookingErrorCodes.invalidAmount,
              },
            ),
          ),
    );

    await harness.submit();

    expect(find.text(FormValidators.invalidAmountMessage), findsOneWidget);

    await harness.type('Депозит', '40 000');
    expect(find.text(FormValidators.invalidAmountMessage), findsNothing);
  });

  testWidgets('dates taken meanwhile show a snackbar and stay', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.createResult = const Left<Failure, String>(
            ValidationFailure(code: BookingErrorCodes.datesUnavailable),
          ),
    );

    await harness.submit();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Эти даты уже заняты другой бронью'), findsOneWidget);
    expect(harness.location, '/bookings/new/guest');
  });

  testWidgets('a stale draft shows a snackbar and goes back to step 1', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.createResult = const Left<Failure, String>(
            ServerFailure(
              statusCode: 404,
              code: BookingErrorCodes.draftNotFound,
            ),
          ),
    );

    await harness.submit();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Черновик брони устарел. Заполните её заново'),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(harness.location, AppRoutes.newBooking.path);
  });

  testWidgets('without a draft it goes to step 1', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) => repository.draftResult =
          Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft()),
    );

    expect(harness.location, AppRoutes.newBooking.path);
    expect(find.text('Step 1 page'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) => repository.draftResult =
          const Left<Failure, CurrentBookingDraftEntity>(ConnectionFailure()),
    );

    expect(find.text('Не удалось загрузить бронь'), findsOneWidget);
    expect(harness.createButton, findsNothing);

    harness.repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
      testCurrentDraft(testDraft()),
    );
    await harness.tapText('Повторить');

    expect(harness.repository.draftCount, 2);
    expect(harness.createButton, findsOneWidget);
  });

  testWidgets('creating shows loading and blocks a second submit', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository) =>
          repository.holdCreate = true,
    );

    await harness.submit();

    // The label gives way to a progress indicator while creating.
    final Finder button = find.byType(FilledButton);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(tester.widget<TextField>(harness.field('Итого')).enabled, isFalse);
    await tester.tap(button, warnIfMissed: false);
    await tester.pump();
    expect(harness.repository.createCalls, hasLength(1));

    harness.repository.heldCreate.single.complete(
      const Right<Failure, String>('booking-1061'),
    );
    await tester.pumpAndSettle();
    expect(harness.location, '/bookings/booking-1061');
  });

  testWidgets('«Назад» returns to step 1', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Назад'));
    await tester.pumpAndSettle();

    expect(harness.location, AppRoutes.newBooking.path);
    expect(find.text('Step 1 page'), findsOneWidget);
  });
}
