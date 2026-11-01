import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/save_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/search_booking_guests_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_draft_bloc/booking_draft_bloc.dart';
import 'package:easy_booking/features/bookings/presentation/screens/new_booking_screen.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';

import '../../../../helpers/fake_bookings_repository.dart';
import '../../../../helpers/fake_properties_repository.dart';

/// [NewBookingScreen] in a small GoRouter: `/today`, `/bookings/new`, and
/// its step 2 `/bookings/new/guest`, which only shows a text.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.properties);

  final WidgetTester tester;
  final GoRouter router;
  final FakeBookingsRepository repository;
  final FakePropertiesRepository properties;

  static Future<_Harness> pump(
    WidgetTester tester, {
    void Function(FakeBookingsRepository, FakePropertiesRepository)? arrange,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeBookingsRepository repository = FakeBookingsRepository();
    final FakePropertiesRepository properties = FakePropertiesRepository();
    arrange?.call(repository, properties);

    final GoRouter router = GoRouter(
      initialLocation: AppRoutes.newBooking.path,
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.today.name,
          path: AppRoutes.today.path,
          builder: (_, _) => const Scaffold(body: Text('Today page')),
        ),
        GoRoute(
          name: AppRoutes.newBooking.name,
          path: AppRoutes.newBooking.path,
          // The provider owns the BLoC and closes it with the route.
          builder: (_, _) => BlocProvider<BookingDraftBloc>(
            create: (_) => BookingDraftBloc(
              getProperties: GetPropertiesUsecase(properties),
              getDraft: GetBookingDraftUsecase(repository),
              searchGuests: SearchBookingGuestsUsecase(repository),
              saveDraft: SaveBookingDraftUsecase(repository),
            )..add(const BookingDraftStarted()),
            child: const NewBookingScreen(),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.newBookingGuest.name,
              path: AppRoutes.newBookingGuest.path,
              builder: (_, _) => const Scaffold(body: Text('Step 2 page')),
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
    }
    return _Harness(tester, router, repository, properties);
  }

  /// The top-most route, including routes opened with `push`.
  String get location => router.state.uri.path;

  Finder field(String label) {
    return find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );
  }

  Finder get searchInput {
    return find.descendant(
      of: find.byType(AppSearchField),
      matching: find.byType(TextField),
    );
  }

  Finder get submitButton => find.widgetWithText(FilledButton, 'Продолжить');

  String text(String label) {
    return tester.widget<TextField>(field(label)).controller!.text;
  }

  Future<void> type(String label, String text) async {
    await tester.ensureVisible(field(label));
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  Future<void> pickProperty(String title) async {
    await tester.tap(find.text('Выберите квартиру'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text(title)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill({
    String firstName = 'Айжан',
    String lastName = 'Сарсенова',
    String phone = '+7 701 245 18 92',
  }) async {
    await pickProperty('Esentai City · 84');
    await type('Имя', firstName);
    await type('Фамилия', lastName);
    await type('Телефон', phone);
  }

  Future<void> submit() async {
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump();
  }
}

/// `28 окт, 14:00`, as the date fields show it.
String _dateLabel(DateTime value) {
  return '${DateFormatter.dayMonth(value, short: true)}, '
      '${DateFormatter.time(value)}';
}

void main() {
  testWidgets('shows a skeleton, then the form', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(
      tester,
      settle: false,
      arrange: (_, FakePropertiesRepository properties) =>
          properties.holdProperties = true,
    );
    await tester.pump();

    expect(find.text('Когда и где'), findsOneWidget);
    expect(find.byType(AppSkeleton), findsWidgets);
    expect(find.text('Квартира'), findsNothing);
    expect(harness.submitButton, findsNothing);

    harness.properties.heldProperties.single.complete(
      Right<Failure, List<PropertyEntity>>(testProperties()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppSkeleton), findsNothing);
    for (final String label in <String>[
      'Квартира',
      'Заезд',
      'Выезд',
      'Гость',
      'Имя',
      'Фамилия',
      'Телефон',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Выберите квартиру'), findsOneWidget);
    expect(find.text('Найти существующего гостя'), findsOneWidget);
    expect(harness.submitButton, findsOneWidget);
  });

  testWidgets('a failed load offers a retry that shows the form', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (_, FakePropertiesRepository properties) =>
          properties.propertiesResult =
              const Left<Failure, List<PropertyEntity>>(ConnectionFailure()),
    );

    expect(find.text('Не удалось загрузить квартиры'), findsOneWidget);
    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(harness.submitButton, findsNothing);

    harness.properties.propertiesResult = Right<Failure, List<PropertyEntity>>(
      testProperties(),
    );
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(harness.properties.propertiesCount, 2);
    expect(find.text('Не удалось загрузить квартиры'), findsNothing);
    expect(find.text('Выберите квартиру'), findsOneWidget);
  });

  testWidgets('dates default to tomorrow 14:00 and the day after 12:00', (
    WidgetTester tester,
  ) async {
    // The source's today is 22 October.
    await _Harness.pump(tester);

    expect(find.text('23 окт, 14:00'), findsOneWidget);
    expect(find.text('24 окт, 12:00'), findsOneWidget);
  });

  testWidgets('the default dates follow the source\'s today across a month', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
            CurrentBookingDraftEntity(today: DateTime(2026, 10, 30)),
          ),
    );

    expect(find.text('31 окт, 14:00'), findsOneWidget);
    expect(find.text('1 ноя, 12:00'), findsOneWidget);
  });

  testWidgets('a saved draft prefills the form', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
            testCurrentDraft(testDraft()),
          ),
    );

    expect(find.text('Esentai City · 84'), findsOneWidget);
    expect(find.text('Выберите квартиру'), findsNothing);
    expect(find.text(_dateLabel(DateTime(2026, 10, 28, 14))), findsOneWidget);
    expect(find.text(_dateLabel(DateTime(2026, 10, 31, 12))), findsOneWidget);
    expect(harness.text('Имя'), 'Айжан');
    expect(harness.text('Фамилия'), 'Сарсенова');
    expect(harness.text('Телефон'), '+7 701 245 18 92');

    // The prefilled form can be submitted as is.
    await harness.submit();
    expect(
      harness.repository.saveDraftCalls,
      <SaveBookingDraftParamsEntity>[
        SaveBookingDraftParamsEntity(
          propertyId: 'p1',
          checkIn: DateTime(2026, 10, 28, 14),
          checkOut: DateTime(2026, 10, 31, 12),
          firstName: 'Айжан',
          lastName: 'Сарсенова',
          phone: '+77012451892',
        ),
      ],
    );
  });

  testWidgets('an empty form shows the errors and saves nothing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.submit();

    // The apartment and the first name are required.
    expect(find.text(FormValidators.requiredMessage), findsNWidgets(2));
    expect(find.text(FormValidators.invalidPhoneMessage), findsOneWidget);
    expect(harness.repository.saveDraftCalls, isEmpty);
    expect(harness.location, AppRoutes.newBooking.path);
  });

  testWidgets('an invalid phone shows its error and saves nothing', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    await harness.fill(phone: '+7 701 245');

    await harness.submit();

    expect(find.text(FormValidators.invalidPhoneMessage), findsOneWidget);
    expect(find.text(FormValidators.requiredMessage), findsNothing);
    expect(harness.repository.saveDraftCalls, isEmpty);

    // The error clears while the user fixes the number.
    await harness.type('Телефон', '+7 701 245 18 92');
    expect(find.text(FormValidators.invalidPhoneMessage), findsNothing);
  });

  testWidgets('a valid form saves the draft and opens step 2', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    await harness.fill(
      firstName: '  Айжан ',
      lastName: '',
      phone: '8 701 245 18 92',
    );

    await harness.submit();
    await tester.pumpAndSettle();

    expect(
      harness.repository.saveDraftCalls,
      <SaveBookingDraftParamsEntity>[
        SaveBookingDraftParamsEntity(
          propertyId: 'p1',
          // The defaults from the source's today, 22 October.
          checkIn: DateTime(2026, 10, 23, 14),
          checkOut: DateTime(2026, 10, 24, 12),
          firstName: 'Айжан',
          lastName: '',
          phone: '+77012451892',
        ),
      ],
    );
    expect(harness.location, '/bookings/new/guest');
    expect(find.text('Step 2 page'), findsOneWidget);
  });

  testWidgets('server field errors show under their fields and clear on edit', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.saveDraftResult = const Left<Failure, BookingDraftEntity>(
            ValidationFailure(
              fieldErrors: <String, String>{
                BookingFields.phone: BookingErrorCodes.invalidPhone,
                BookingFields.checkOut: BookingErrorCodes.checkOutBeforeCheckIn,
              },
            ),
          ),
    );
    await harness.fill();

    await harness.submit();

    expect(harness.repository.saveDraftCalls, hasLength(1));
    expect(find.text(FormValidators.invalidPhoneMessage), findsOneWidget);
    expect(
      find.text('Выезд должен быть хотя бы на день позже заезда'),
      findsOneWidget,
    );
    expect(harness.location, AppRoutes.newBooking.path);

    await harness.type('Телефон', '+7 701 245 18 93');

    expect(find.text(FormValidators.invalidPhoneMessage), findsNothing);
    expect(
      find.text('Выезд должен быть хотя бы на день позже заезда'),
      findsOneWidget,
    );
  });

  testWidgets('a request failure shows a snackbar', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.saveDraftResult = const Left<Failure, BookingDraftEntity>(
            ConnectionFailure(),
          ),
    );
    await harness.fill();

    await harness.submit();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(harness.location, AppRoutes.newBooking.path);
  });

  testWidgets('saving shows loading and blocks a second submit', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.holdSaveDraft = true,
    );
    await harness.fill();

    await harness.submit();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.widget<TextField>(harness.field('Имя')).enabled, isFalse);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(harness.repository.saveDraftCalls, hasLength(1));

    harness.repository.heldSaveDraft.single.complete(
      Right<Failure, BookingDraftEntity>(testDraft()),
    );
    await tester.pumpAndSettle();
    expect(harness.location, '/bookings/new/guest');
  });

  testWidgets('picking an earlier guest fills the guest fields', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.guestsResult =
              const Right<Failure, List<BookingGuestEntity>>(
                <BookingGuestEntity>[testAizhan, testDaniyar],
              ),
    );

    await tester.ensureVisible(harness.searchInput);
    await tester.enterText(harness.searchInput, 'Ай');
    await tester.pump(BookingDraftBloc.guestSearchDebounce);
    await tester.pumpAndSettle();

    expect(harness.repository.guestQueries, <String>['Ай']);
    expect(find.text('Айжан Сарсенова'), findsOneWidget);
    expect(find.text('Данияр Муратов'), findsOneWidget);

    await tester.tap(find.text('Данияр Муратов'));
    await tester.pump(BookingDraftBloc.guestSearchDebounce);
    await tester.pumpAndSettle();

    expect(harness.text('Имя'), 'Данияр');
    expect(harness.text('Фамилия'), 'Муратов');
    expect(harness.text('Телефон'), '+7 700 318 45 21');
    expect(
      tester.widget<TextField>(harness.searchInput).controller!.text,
      isEmpty,
    );
    expect(find.text('Айжан Сарсенова'), findsNothing);
    // A blank query sends no request.
    expect(harness.repository.guestQueries, <String>['Ай']);
  });

  testWidgets('a search without results says so', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(
      tester,
      arrange: (FakeBookingsRepository repository, _) =>
          repository.guestsResult =
              const Right<Failure, List<BookingGuestEntity>>(
                <BookingGuestEntity>[],
              ),
    );

    await tester.ensureVisible(harness.searchInput);
    await tester.enterText(harness.searchInput, 'Зарина');
    await tester.pump(BookingDraftBloc.guestSearchDebounce);
    await tester.pumpAndSettle();

    expect(find.text('Гость не найден. Заполните данные ниже'), findsOneWidget);
  });

  testWidgets('back without history goes to today', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(harness.location, AppRoutes.today.path);
    expect(find.text('Today page'), findsOneWidget);
  });

  testWidgets('closing the screen while the load runs is safe', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      settle: false,
      arrange: (_, FakePropertiesRepository properties) =>
          properties.holdProperties = true,
    );
    await tester.pump();

    harness.router.goNamed(AppRoutes.today.name);
    await tester.pumpAndSettle();
    harness.properties.heldProperties.single.complete(
      Right<Failure, List<PropertyEntity>>(testProperties()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
