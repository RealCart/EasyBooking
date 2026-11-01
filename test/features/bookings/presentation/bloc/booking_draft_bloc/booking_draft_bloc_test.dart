import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
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
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';

import '../../../../../helpers/fake_bookings_repository.dart';
import '../../../../../helpers/fake_properties_repository.dart';

const Failure _connection = ConnectionFailure();

SaveBookingDraftParamsEntity _params({
  String firstName = 'Айжан',
  String phone = '+7 701 245 18 92',
}) {
  return SaveBookingDraftParamsEntity(
    propertyId: 'p1',
    checkIn: DateTime(2026, 10, 28, 14),
    checkOut: DateTime(2026, 10, 31, 12),
    firstName: firstName,
    lastName: 'Сарсенова',
    phone: phone,
  );
}

/// A [BookingDraftBloc] over fake repositories that records its states and
/// errors.
final class _Subject {
  _Subject() {
    bloc = BookingDraftBloc(
      getProperties: GetPropertiesUsecase(properties),
      getDraft: GetBookingDraftUsecase(repository),
      searchGuests: SearchBookingGuestsUsecase(repository),
      saveDraft: SaveBookingDraftUsecase(repository),
    );
    final StreamSubscription<BookingDraftState> subscription = bloc.stream
        .listen(states.add, onError: errors.add);
    addTearDown(subscription.cancel);
  }

  final FakeBookingsRepository repository = FakeBookingsRepository();
  final FakePropertiesRepository properties = FakePropertiesRepository();
  late final BookingDraftBloc bloc;
  final List<BookingDraftState> states = <BookingDraftState>[];
  final List<Object> errors = <Object>[];
}

/// Closes [bloc] inside the `testWidgets` fake-async zone; `Bloc.close`
/// does not complete there, so it is not awaited.
Future<void> _close(WidgetTester tester, BookingDraftBloc bloc) async {
  unawaited(bloc.close());
  await tester.pump();
  expect(bloc.isClosed, isTrue);
}

/// Searches [query] and waits out the debounce.
Future<void> _search(
  WidgetTester tester,
  _Subject subject,
  String query,
) async {
  subject.bloc.add(BookingDraftGuestSearched(query));
  await tester.pump(BookingDraftBloc.guestSearchDebounce);
  await tester.pump();
}

void main() {
  group('BookingDraftBloc load', () {
    test('starts idle and empty', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      expect(subject.bloc.state, const BookingDraftState());
    });

    test('a start loads the apartments and no draft', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();

      expect(subject.properties.propertiesCount, 1);
      expect(subject.repository.draftCount, 1);
      expect(subject.states, <BookingDraftState>[
        const BookingDraftState(loadStatus: RequestStatus.loading),
        BookingDraftState(
          loadStatus: RequestStatus.success,
          properties: testProperties(),
          today: bookingsTestToday,
        ),
      ]);
      expect(
        () => subject.bloc.state.properties.add(testProperties().first),
        throwsUnsupportedError,
      );
    });

    test('a start loads the saved draft for prefilling', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.draftResult =
          Right<Failure, CurrentBookingDraftEntity>(
            testCurrentDraft(testDraft()),
          );

      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();

      expect(subject.bloc.state.loadStatus, RequestStatus.success);
      expect(subject.bloc.state.draft, testDraft());
      expect(subject.bloc.state.today, bookingsTestToday);
    });

    test('a properties failure fails the load', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.properties.propertiesResult =
          const Left<Failure, List<PropertyEntity>>(_connection);

      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();

      expect(
        subject.states.last,
        const BookingDraftState(
          loadStatus: RequestStatus.failure,
          loadFailure: _connection,
        ),
      );
    });

    test('a draft failure fails the load', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.draftResult =
          const Left<Failure, CurrentBookingDraftEntity>(
            _connection,
          );

      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();

      expect(
        subject.states.last,
        const BookingDraftState(
          loadStatus: RequestStatus.failure,
          loadFailure: _connection,
        ),
      );
    });

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.properties.propertiesResult =
          const Left<Failure, List<PropertyEntity>>(_connection);
      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();
      subject.states.clear();
      subject.properties.propertiesResult =
          Right<Failure, List<PropertyEntity>>(testProperties());

      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();

      expect(subject.states, <BookingDraftState>[
        const BookingDraftState(loadStatus: RequestStatus.loading),
        BookingDraftState(
          loadStatus: RequestStatus.success,
          properties: testProperties(),
          today: bookingsTestToday,
        ),
      ]);
    });

    test('closing while the load is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.properties.holdProperties = true;
      subject.bloc.add(const BookingDraftStarted());
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.properties.heldProperties.single.complete(
        Right<Failure, List<PropertyEntity>>(testProperties()),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });

  group('BookingDraftBloc guest search', () {
    testWidgets('typing runs one search for the last query after 300 ms', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      subject.bloc.add(const BookingDraftGuestSearched('А'));
      await tester.pump(const Duration(milliseconds: 200));
      subject.bloc.add(const BookingDraftGuestSearched('Ай'));
      await tester.pump(const Duration(milliseconds: 200));
      subject.bloc.add(const BookingDraftGuestSearched('Айж'));
      await tester.pump(const Duration(milliseconds: 299));
      expect(subject.repository.guestQueries, isEmpty);
      expect(subject.states, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(subject.repository.guestQueries, <String>['Айж']);
      expect(subject.states, <BookingDraftState>[
        const BookingDraftState(
          guestQuery: 'Айж',
          guestSearchStatus: RequestStatus.loading,
        ),
        const BookingDraftState(
          guestQuery: 'Айж',
          guestSearchStatus: RequestStatus.success,
          guests: <BookingGuestEntity>[testAizhan],
        ),
      ]);
      expect(
        () => subject.bloc.state.guests.add(testDaniyar),
        throwsUnsupportedError,
      );

      await _close(tester, subject.bloc);
    });

    testWidgets('the query is trimmed before the search', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      await _search(tester, subject, '  Айжан  ');

      expect(subject.repository.guestQueries, <String>['Айжан']);
      expect(subject.bloc.state.guestQuery, 'Айжан');

      await _close(tester, subject.bloc);
    });

    testWidgets('a blank query clears the results without a request', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      await _search(tester, subject, 'Айж');
      subject.states.clear();

      await _search(tester, subject, '   ');

      expect(subject.repository.guestQueries, <String>['Айж']);
      expect(subject.states, <BookingDraftState>[const BookingDraftState()]);

      await _close(tester, subject.bloc);
    });

    testWidgets('a failed search reports it without guests', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      await _search(tester, subject, 'Айж');
      subject.repository.guestsResult =
          const Left<Failure, List<BookingGuestEntity>>(_connection);

      await _search(tester, subject, 'Дан');

      expect(
        subject.bloc.state,
        const BookingDraftState(
          guestQuery: 'Дан',
          guestSearchStatus: RequestStatus.failure,
          guestSearchFailure: _connection,
        ),
      );

      // The next search clears the failure while it runs.
      subject.repository.holdGuests = true;
      await _search(tester, subject, 'Данияр');
      expect(subject.bloc.state.guestSearchStatus, RequestStatus.loading);
      expect(subject.bloc.state.guestSearchFailure, isNull);

      await _close(tester, subject.bloc);
    });

    testWidgets('a stale search A never replaces the newer search B', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdGuests = true;
      await _search(tester, subject, 'Ай');
      await _search(tester, subject, 'Да');
      expect(subject.repository.guestQueries, <String>['Ай', 'Да']);

      subject.repository.heldGuests[1].complete(
        const Right<Failure, List<BookingGuestEntity>>(<BookingGuestEntity>[
          testDaniyar,
        ]),
      );
      await tester.pump();
      subject.repository.heldGuests[0].complete(
        const Right<Failure, List<BookingGuestEntity>>(<BookingGuestEntity>[
          testAizhan,
        ]),
      );
      await tester.pump();

      expect(subject.bloc.state.guestQuery, 'Да');
      expect(subject.bloc.state.guests, <BookingGuestEntity>[testDaniyar]);
      expect(
        subject.states.where(
          (BookingDraftState state) => state.guests.contains(testAizhan),
        ),
        isEmpty,
      );

      await _close(tester, subject.bloc);
    });

    testWidgets('a pending debounced search is dropped on close', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();

      subject.bloc.add(const BookingDraftGuestSearched('Айж'));
      await tester.pump(const Duration(milliseconds: 100));
      await _close(tester, subject.bloc);
      await tester.pump(BookingDraftBloc.guestSearchDebounce * 2);

      expect(subject.repository.guestQueries, isEmpty);
      expect(subject.errors, isEmpty);
    });

    testWidgets('closing while a search is awaited emits nothing more', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject();
      subject.repository.holdGuests = true;
      await _search(tester, subject, 'Айж');
      subject.states.clear();

      await _close(tester, subject.bloc);
      subject.repository.heldGuests.single.complete(
        const Right<Failure, List<BookingGuestEntity>>(<BookingGuestEntity>[
          testAizhan,
        ]),
      );
      await tester.pump();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });

  group('BookingDraftBloc submit', () {
    test('a valid form saves the draft', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.repository.saveDraftCalls.single.phone, '+77012451892');
      expect(subject.states, <BookingDraftState>[
        const BookingDraftState(submitStatus: RequestStatus.loading),
        BookingDraftState(
          submitStatus: RequestStatus.success,
          draft: testDraft(),
        ),
      ]);
    });

    test('a rule broken in the use case shows field errors', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      subject.bloc.add(
        BookingDraftSubmitted(_params(firstName: ' ', phone: '123')),
      );
      await pumpEventQueue();

      expect(subject.repository.saveDraftCalls, isEmpty);
      expect(
        subject.states.last,
        const BookingDraftState(
          submitStatus: RequestStatus.failure,
          fieldErrors: <String, String>{
            BookingFields.firstName: BookingErrorCodes.required,
            BookingFields.phone: BookingErrorCodes.invalidPhone,
          },
        ),
      );
      expect(
        () => subject.bloc.state.fieldErrors['x'] = 'y',
        throwsUnsupportedError,
      );
    });

    test(
      'an error of a field not on the screen is a general failure',
      () async {
        final _Subject subject = _Subject();
        addTearDown(subject.bloc.close);
        const Failure failure = ValidationFailure(
          fieldErrors: <String, String>{'guest_count': 'required'},
        );
        subject.repository.saveDraftResult =
            const Left<Failure, BookingDraftEntity>(failure);

        subject.bloc.add(BookingDraftSubmitted(_params()));
        await pumpEventQueue();

        expect(subject.bloc.state.submitStatus, RequestStatus.failure);
        expect(subject.bloc.state.fieldErrors, <String, String>{
          'guest_count': 'required',
        });
        expect(subject.bloc.state.submitFailure, failure);
      },
    );

    test('a request failure is a general failure', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.saveDraftResult =
          const Left<Failure, BookingDraftEntity>(_connection);

      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();

      expect(
        subject.states.last,
        const BookingDraftState(
          submitStatus: RequestStatus.failure,
          submitFailure: _connection,
        ),
      );
    });

    test('editing a field clears only its error', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.bloc.add(
        BookingDraftSubmitted(_params(firstName: '', phone: '1')),
      );
      await pumpEventQueue();
      subject.states.clear();

      subject.bloc.add(const BookingDraftFieldEdited(BookingFields.phone));
      await pumpEventQueue();

      expect(subject.states, <BookingDraftState>[
        const BookingDraftState(
          fieldErrors: <String, String>{
            BookingFields.firstName: BookingErrorCodes.required,
          },
        ),
      ]);
    });

    test('editing clears a general failure', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.saveDraftResult =
          const Left<Failure, BookingDraftEntity>(_connection);
      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();

      subject.bloc.add(const BookingDraftFieldEdited(BookingFields.lastName));
      await pumpEventQueue();

      expect(subject.bloc.state, const BookingDraftState());
    });

    test('editing without an error emits nothing', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);

      subject.bloc.add(const BookingDraftFieldEdited(BookingFields.phone));
      await pumpEventQueue();

      expect(subject.states, isEmpty);
    });

    test('a second submit while one runs is dropped', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.repository.holdSaveDraft = true;

      subject.bloc
        ..add(BookingDraftSubmitted(_params()))
        ..add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.repository.saveDraftCalls, hasLength(1));
      subject.repository.heldSaveDraft.single.complete(
        Right<Failure, BookingDraftEntity>(testDraft()),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.submitStatus, RequestStatus.success);
    });

    test('saving again after a success is allowed', () async {
      final _Subject subject = _Subject();
      addTearDown(subject.bloc.close);
      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();
      subject.repository.saveDraftResult = Right<Failure, BookingDraftEntity>(
        testDraft(id: 'draft-2'),
      );

      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.repository.saveDraftCalls, hasLength(2));
      expect(subject.bloc.state.draft?.id, 'draft-2');
    });

    test('closing while a submit is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSaveDraft = true;
      subject.bloc.add(BookingDraftSubmitted(_params()));
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldSaveDraft.single.complete(
        Right<Failure, BookingDraftEntity>(testDraft()),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });
}
