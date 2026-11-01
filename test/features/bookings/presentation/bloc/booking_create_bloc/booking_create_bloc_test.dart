import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_create_bloc/booking_create_bloc.dart';

import '../../../../../helpers/fake_bookings_repository.dart';

const Failure _connection = ConnectionFailure();
const Failure _datesUnavailable = ValidationFailure(
  code: BookingErrorCodes.datesUnavailable,
);

CreateBookingParamsEntity _params({
  int totalPrice = 127500,
  int deposit = 50000,
  BookingSource source = BookingSource.direct,
}) {
  return CreateBookingParamsEntity(
    draftId: 'draft-1',
    totalPrice: totalPrice,
    deposit: deposit,
    source: source,
    createContract: true,
  );
}

/// A [BookingCreateBloc] over a [FakeBookingsRepository] that records its
/// states and errors.
final class _Subject {
  _Subject() {
    repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
      testCurrentDraft(testDraft()),
    );
    bloc = BookingCreateBloc(
      getDraft: GetBookingDraftUsecase(repository),
      createBooking: CreateBookingUsecase(repository),
    );
    final StreamSubscription<BookingCreateState> subscription = bloc.stream
        .listen(states.add, onError: errors.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeBookingsRepository repository = FakeBookingsRepository();
  late final BookingCreateBloc bloc;
  final List<BookingCreateState> states = <BookingCreateState>[];
  final List<Object> errors = <Object>[];

  BookingCreateState get loaded {
    return BookingCreateState(
      loadStatus: RequestStatus.success,
      draft: testDraft(),
    );
  }

  /// Loads [testDraft] and forgets the states of the load.
  Future<void> load() async {
    bloc.add(const BookingCreateStarted());
    await pumpEventQueue();
    states.clear();
  }
}

void main() {
  group('BookingCreateBloc load', () {
    test('starts idle without a draft', () {
      expect(_Subject().bloc.state, const BookingCreateState());
    });

    test('a start emits loading, then the draft', () async {
      final _Subject subject = _Subject();

      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();

      expect(subject.repository.draftCount, 1);
      expect(subject.states, <BookingCreateState>[
        const BookingCreateState(loadStatus: RequestStatus.loading),
        subject.loaded,
      ]);
    });

    test('no draft is a success with a null draft', () async {
      final _Subject subject = _Subject();
      subject.repository.draftResult =
          Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft());

      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();

      expect(
        subject.states.last,
        const BookingCreateState(loadStatus: RequestStatus.success),
      );
    });

    test('a reload finding no draft drops the old one', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.draftResult =
          Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft());

      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();

      expect(subject.bloc.state.draft, isNull);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('a failed load reports the failure; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.draftResult =
          const Left<Failure, CurrentBookingDraftEntity>(
            _connection,
          );
      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();
      expect(
        subject.states.last,
        const BookingCreateState(
          loadStatus: RequestStatus.failure,
          loadFailure: _connection,
        ),
      );
      subject.states.clear();
      subject.repository.draftResult =
          Right<Failure, CurrentBookingDraftEntity>(
            testCurrentDraft(testDraft()),
          );

      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();

      expect(subject.states, <BookingCreateState>[
        const BookingCreateState(loadStatus: RequestStatus.loading),
        subject.loaded,
      ]);
    });

    test('closing while the load is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdDraft = true;
      subject.bloc.add(const BookingCreateStarted());
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldDraft.single.complete(
        Right<Failure, CurrentBookingDraftEntity>(
          testCurrentDraft(testDraft()),
        ),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });

  group('BookingCreateBloc submit', () {
    test('a valid form creates the booking', () async {
      final _Subject subject = _Subject();
      await subject.load();

      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.repository.createCalls, <CreateBookingParamsEntity>[
        _params(),
      ]);
      expect(subject.states, <BookingCreateState>[
        subject.loaded.copyWith(submitStatus: RequestStatus.loading),
        subject.loaded.copyWith(
          submitStatus: RequestStatus.success,
          createdBookingId: 'booking-1060',
        ),
      ]);
    });

    test('a submit after a success is ignored', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();
      subject.states.clear();

      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.repository.createCalls, hasLength(1));
      expect(subject.states, isEmpty);
    });

    test('a second submit while one runs is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdCreate = true;

      subject.bloc
        ..add(BookingCreateSubmitted(_params()))
        ..add(BookingCreateSubmitted(_params(totalPrice: 1)));
      await pumpEventQueue();

      expect(subject.repository.createCalls, <CreateBookingParamsEntity>[
        _params(),
      ]);
      subject.repository.heldCreate.single.complete(
        const Right<Failure, String>('booking-1060'),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.createdBookingId, 'booking-1060');
    });

    test('broken amounts show field errors without a request', () async {
      final _Subject subject = _Subject();
      await subject.load();

      subject.bloc.add(
        BookingCreateSubmitted(_params(totalPrice: 0, deposit: -5)),
      );
      await pumpEventQueue();

      expect(subject.repository.createCalls, isEmpty);
      expect(
        subject.states.last,
        subject.loaded.copyWith(
          submitStatus: RequestStatus.failure,
          fieldErrors: const <String, String>{
            BookingFields.totalPrice: BookingErrorCodes.invalidAmount,
            BookingFields.deposit: BookingErrorCodes.invalidAmount,
          },
        ),
      );
      expect(subject.bloc.state.submitFailure, isNull);
    });

    test('a channel source shows the source error', () async {
      final _Subject subject = _Subject();
      await subject.load();

      subject.bloc.add(
        BookingCreateSubmitted(_params(source: BookingSource.airbnb)),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.fieldErrors, <String, String>{
        BookingFields.source: BookingErrorCodes.unsupportedSource,
      });
      expect(subject.bloc.state.submitFailure, isNull);
    });

    test(
      'an error of a field not on the screen is a general failure',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        const Failure failure = ValidationFailure(
          fieldErrors: <String, String>{'comment': 'too_long'},
        );
        subject.repository.createResult = const Left<Failure, String>(failure);

        subject.bloc.add(BookingCreateSubmitted(_params()));
        await pumpEventQueue();

        expect(subject.bloc.state.submitFailure, failure);
        expect(subject.bloc.state.fieldErrors, <String, String>{
          'comment': 'too_long',
        });
      },
    );

    test('dates taken meanwhile are a general failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.createResult = const Left<Failure, String>(
        _datesUnavailable,
      );

      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();

      expect(
        subject.states.last,
        subject.loaded.copyWith(
          submitStatus: RequestStatus.failure,
          submitFailure: _datesUnavailable,
        ),
      );
    });

    test('a retry after a failure clears it while loading', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.createResult = const Left<Failure, String>(
        _connection,
      );
      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();
      subject.states.clear();
      subject.repository.createResult = const Right<Failure, String>(
        'booking-1061',
      );

      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();

      expect(subject.states, <BookingCreateState>[
        subject.loaded.copyWith(submitStatus: RequestStatus.loading),
        subject.loaded.copyWith(
          submitStatus: RequestStatus.success,
          createdBookingId: 'booking-1061',
        ),
      ]);
    });

    test('editing a field clears only its error', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.bloc.add(
        BookingCreateSubmitted(_params(totalPrice: 0, deposit: -5)),
      );
      await pumpEventQueue();
      subject.states.clear();

      subject.bloc.add(const BookingCreateFieldEdited(BookingFields.deposit));
      await pumpEventQueue();

      expect(subject.states, <BookingCreateState>[
        subject.loaded.copyWith(
          fieldErrors: const <String, String>{
            BookingFields.totalPrice: BookingErrorCodes.invalidAmount,
          },
        ),
      ]);
    });

    test('editing clears a general failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.createResult = const Left<Failure, String>(
        _datesUnavailable,
      );
      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();

      subject.bloc.add(const BookingCreateFieldEdited(BookingFields.source));
      await pumpEventQueue();

      expect(subject.bloc.state, subject.loaded);
    });

    test('editing without an error emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();

      subject.bloc.add(
        const BookingCreateFieldEdited(BookingFields.totalPrice),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
    });

    test('closing while a submit is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdCreate = true;
      subject.bloc.add(BookingCreateSubmitted(_params()));
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldCreate.single.complete(
        const Right<Failure, String>('booking-1060'),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });
}
