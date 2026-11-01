import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:easy_booking/features/bookings/presentation/bloc/booking_detail_bloc/booking_detail_bloc.dart';

import '../../../../../helpers/fake_bookings_repository.dart';

const Failure _notFound = ServerFailure(statusCode: 404);
const Failure _connection = ConnectionFailure();
const Failure _notCancellable = ValidationFailure(
  code: BookingErrorCodes.notCancellable,
);

/// A [BookingDetailBloc] over a [FakeBookingsRepository] that records its
/// states and errors.
final class _Subject {
  _Subject() {
    bloc = BookingDetailBloc(
      getBooking: GetBookingUsecase(repository),
      cancelBooking: CancelBookingUsecase(repository),
    );
    final StreamSubscription<BookingDetailState> subscription = bloc.stream
        .listen(states.add, onError: errors.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeBookingsRepository repository = FakeBookingsRepository();
  late final BookingDetailBloc bloc;
  final List<BookingDetailState> states = <BookingDetailState>[];
  final List<Object> errors = <Object>[];

  /// Loads [testBooking] and forgets the states of the load.
  Future<void> load([String id = 'b1']) async {
    bloc.add(BookingDetailRequested(id));
    await pumpEventQueue();
    states.clear();
  }
}

void main() {
  group('BookingDetailBloc', () {
    test('starts idle without a booking', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const BookingDetailState());
      expect(subject.bloc.state.canCancel, isFalse);
    });

    test('a request emits loading, then the booking', () async {
      final _Subject subject = _Subject();

      subject.bloc.add(const BookingDetailRequested('b1'));
      await pumpEventQueue();

      expect(subject.repository.bookingIds, <String>['b1']);
      expect(subject.states, <BookingDetailState>[
        const BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.loading,
        ),
        BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.success,
          booking: testBooking(),
        ),
      ]);
      expect(subject.bloc.state.canCancel, isTrue);
    });

    test('an unknown booking ends in a failure', () async {
      final _Subject subject = _Subject();
      subject.repository.bookingResult = const Left<Failure, BookingEntity>(
        _notFound,
      );

      subject.bloc.add(const BookingDetailRequested('missing'));
      await pumpEventQueue();

      expect(
        subject.states.last,
        const BookingDetailState(
          bookingId: 'missing',
          loadStatus: RequestStatus.failure,
          loadFailure: _notFound,
        ),
      );
    });

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      subject.repository.bookingResult = const Left<Failure, BookingEntity>(
        _connection,
      );
      await subject.load();
      subject.repository.bookingResult = Right<Failure, BookingEntity>(
        testBooking(),
      );

      subject.bloc.add(const BookingDetailRequested('b1'));
      await pumpEventQueue();

      expect(subject.states, <BookingDetailState>[
        const BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.loading,
        ),
        BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.success,
          booking: testBooking(),
        ),
      ]);
    });

    test('a failed reload keeps the loaded booking', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.bookingResult = const Left<Failure, BookingEntity>(
        _connection,
      );

      subject.bloc.add(const BookingDetailRequested('b1'));
      await pumpEventQueue();

      expect(subject.bloc.state.loadStatus, RequestStatus.failure);
      expect(subject.bloc.state.loadFailure, _connection);
      expect(subject.bloc.state.booking, testBooking());
    });

    test('a stale response A never replaces the newer response B', () async {
      final _Subject subject = _Subject();
      subject.repository.holdBooking = true;

      subject.bloc
        ..add(const BookingDetailRequested('a'))
        ..add(const BookingDetailRequested('b'));
      await pumpEventQueue();
      expect(subject.repository.bookingIds, <String>['a', 'b']);

      subject.repository.heldBooking[1].complete(
        Right<Failure, BookingEntity>(testBooking(id: 'b')),
      );
      await pumpEventQueue();
      subject.repository.heldBooking[0].complete(
        Right<Failure, BookingEntity>(testBooking(id: 'a')),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.bookingId, 'b');
      expect(subject.bloc.state.booking?.id, 'b');
      expect(
        subject.states.where(
          (BookingDetailState state) => state.booking?.id == 'a',
        ),
        isEmpty,
      );
    });

    test('closing while a request is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdBooking = true;
      subject.bloc.add(const BookingDetailRequested('b1'));
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldBooking.single.complete(
        Right<Failure, BookingEntity>(testBooking()),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });

    test('a cancel emits loading, then the cancelled booking', () async {
      final _Subject subject = _Subject();
      await subject.load();

      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      expect(subject.repository.cancelIds, <String>['b1']);
      expect(subject.states, <BookingDetailState>[
        BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.success,
          booking: testBooking(),
          cancelStatus: RequestStatus.loading,
        ),
        BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.success,
          booking: testBooking(status: BookingStatus.cancelled),
          cancelStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.bloc.state.canCancel, isFalse);
    });

    test('a failed cancel keeps the booking and reports the failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.cancelResult = const Left<Failure, BookingEntity>(
        _notCancellable,
      );

      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      expect(
        subject.states.last,
        BookingDetailState(
          bookingId: 'b1',
          loadStatus: RequestStatus.success,
          booking: testBooking(),
          cancelStatus: RequestStatus.failure,
          cancelFailure: _notCancellable,
        ),
      );
      expect(subject.bloc.state.canCancel, isTrue);
    });

    test('the next cancel clears the previous failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.cancelResult = const Left<Failure, BookingEntity>(
        _connection,
      );
      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();
      subject.states.clear();
      subject.repository.holdCancel = true;

      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      expect(subject.bloc.state.cancelStatus, RequestStatus.loading);
      expect(subject.bloc.state.cancelFailure, isNull);
      expect(subject.bloc.state.canCancel, isFalse);
    });

    test('a cancel without a cancellable booking does nothing', () async {
      final _Subject subject = _Subject();

      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();
      subject.repository.bookingResult = Right<Failure, BookingEntity>(
        testBooking(status: BookingStatus.completed),
      );
      await subject.load();
      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      expect(subject.repository.cancelIds, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('a second cancel while one runs is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdCancel = true;

      subject.bloc
        ..add(const BookingDetailCancelRequested())
        ..add(const BookingDetailCancelRequested());
      await pumpEventQueue();
      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      expect(subject.repository.cancelIds, <String>['b1']);

      subject.repository.heldCancel.single.complete(
        Right<Failure, BookingEntity>(
          testBooking(status: BookingStatus.cancelled),
        ),
      );
      await pumpEventQueue();
      expect(subject.bloc.state.cancelStatus, RequestStatus.success);
    });

    test('a cancel finishing after another booking opened keeps it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdCancel = true;
      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();

      subject.repository.bookingResult = Right<Failure, BookingEntity>(
        testBooking(id: 'b2'),
      );
      subject.bloc.add(const BookingDetailRequested('b2'));
      await pumpEventQueue();
      subject.repository.heldCancel.single.complete(
        Right<Failure, BookingEntity>(
          testBooking(status: BookingStatus.cancelled),
        ),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.bookingId, 'b2');
      expect(subject.bloc.state.booking, testBooking(id: 'b2'));
    });

    test('closing while a cancel is awaited emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdCancel = true;
      subject.bloc.add(const BookingDetailCancelRequested());
      await pumpEventQueue();
      subject.states.clear();

      await subject.bloc.close();
      subject.repository.heldCancel.single.complete(
        Right<Failure, BookingEntity>(
          testBooking(status: BookingStatus.cancelled),
        ),
      );
      await pumpEventQueue();

      expect(subject.states, isEmpty);
      expect(subject.errors, isEmpty);
    });
  });
}
