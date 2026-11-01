import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/data/sources/local/bookings_mock_local.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_availability_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// The fixed clock of the bookings tests: Thursday 22 October 2026, 09:41.
final DateTime bookingsTestNow = DateTime(2026, 10, 22, 9, 41);

/// The source's today in the bookings tests: Thursday 22 October 2026.
final DateTime bookingsTestToday = DateTime(2026, 10, 22);

/// What a draft read answers: [draft], if any, on [bookingsTestToday].
CurrentBookingDraftEntity testCurrentDraft([BookingDraftEntity? draft]) {
  return CurrentBookingDraftEntity(draft: draft, today: bookingsTestToday);
}

const BookingGuestEntity testAizhan = BookingGuestEntity(
  firstName: 'Айжан',
  lastName: 'Сарсенова',
  phone: '+77012451892',
);

const BookingGuestEntity testDaniyar = BookingGuestEntity(
  firstName: 'Данияр',
  lastName: 'Муратов',
  phone: '+77003184521',
);

/// `b1`: Айжан in Esentai City · 84 (`p1`) from 28 to 31 October, with a
/// signed contract `eb-1048`, as answered at [bookingsTestNow].
BookingEntity testBooking({
  String id = 'b1',
  BookingStatus status = BookingStatus.confirmed,
  BookingContractEntity? contract = const BookingContractEntity(
    id: 'eb-1048',
    status: BookingContractStatus.signed,
  ),
  String? comment,
}) {
  return BookingEntity(
    id: id,
    status: status,
    source: BookingSource.airbnb,
    externalCode: 'HM73P2',
    guest: testAizhan,
    guestCount: 2,
    propertyId: 'p1',
    propertyName: 'Esentai City',
    unit: '84',
    checkIn: DateTime(2026, 10, 28, 14),
    checkOut: DateTime(2026, 10, 31, 12),
    totalPrice: 127500,
    deposit: 50000,
    isDepositPaid: false,
    isPaid: true,
    comment: comment,
    contract: contract,
    receivedAt: bookingsTestNow,
  );
}

/// `draft-1`: Айжан in Esentai City · 84 (`p1`) from 28 October 14:00 to
/// 31 October 12:00, quoted at 127 500 ₸ with a 50 000 ₸ deposit.
BookingDraftEntity testDraft({
  String id = 'draft-1',
  List<String> conflictingBookingIds = const <String>[],
}) {
  return BookingDraftEntity(
    id: id,
    propertyId: 'p1',
    propertyName: 'Esentai City',
    unit: '84',
    checkIn: DateTime(2026, 10, 28, 14),
    checkOut: DateTime(2026, 10, 31, 12),
    guest: testAizhan,
    suggestedTotalPrice: 127500,
    suggestedDeposit: 50000,
    availability: BookingAvailabilityEntity(
      checkedChannelNames: const <String>['Booking.com', 'Airbnb'],
      conflictingBookingIds: conflictingBookingIds,
    ),
  );
}

/// [BookingsRepository] with settable results that records every call.
///
/// Set a `hold...` flag to keep the next requests of that kind pending;
/// each gets a completer in the matching `held...` list, in call order.
final class FakeBookingsRepository implements BookingsRepository {
  Either<Failure, BookingEntity> bookingResult = Right<Failure, BookingEntity>(
    testBooking(),
  );
  Either<Failure, BookingEntity>? cancelResult;
  Either<Failure, List<BookingGuestEntity>> guestsResult =
      const Right<Failure, List<BookingGuestEntity>>(<BookingGuestEntity>[
        testAizhan,
      ]);
  Either<Failure, CurrentBookingDraftEntity> draftResult =
      Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft());
  Either<Failure, BookingDraftEntity> saveDraftResult =
      Right<Failure, BookingDraftEntity>(testDraft());
  Either<Failure, String> createResult = const Right<Failure, String>(
    'booking-1060',
  );

  bool holdBooking = false;
  bool holdCancel = false;
  bool holdGuests = false;
  bool holdDraft = false;
  bool holdSaveDraft = false;
  bool holdCreate = false;

  final List<Completer<Either<Failure, BookingEntity>>> heldBooking =
      <Completer<Either<Failure, BookingEntity>>>[];
  final List<Completer<Either<Failure, BookingEntity>>> heldCancel =
      <Completer<Either<Failure, BookingEntity>>>[];
  final List<Completer<Either<Failure, List<BookingGuestEntity>>>> heldGuests =
      <Completer<Either<Failure, List<BookingGuestEntity>>>>[];
  final List<Completer<Either<Failure, CurrentBookingDraftEntity>>> heldDraft =
      <Completer<Either<Failure, CurrentBookingDraftEntity>>>[];
  final List<Completer<Either<Failure, BookingDraftEntity>>> heldSaveDraft =
      <Completer<Either<Failure, BookingDraftEntity>>>[];
  final List<Completer<Either<Failure, String>>> heldCreate =
      <Completer<Either<Failure, String>>>[];

  final List<String> bookingIds = <String>[];
  final List<String> cancelIds = <String>[];
  final List<String> guestQueries = <String>[];
  int draftCount = 0;
  final List<SaveBookingDraftParamsEntity> saveDraftCalls =
      <SaveBookingDraftParamsEntity>[];
  final List<CreateBookingParamsEntity> createCalls =
      <CreateBookingParamsEntity>[];

  @override
  Future<Either<Failure, BookingEntity>> getBooking(String id) {
    bookingIds.add(id);
    return _answer(holdBooking, heldBooking, bookingResult);
  }

  /// Answers [cancelResult], or by default the loaded booking cancelled.
  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) {
    cancelIds.add(id);
    return _answer(
      holdCancel,
      heldCancel,
      cancelResult ??
          Right<Failure, BookingEntity>(
            testBooking(id: id, status: BookingStatus.cancelled),
          ),
    );
  }

  @override
  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(
    String query,
  ) {
    guestQueries.add(query);
    return _answer(holdGuests, heldGuests, guestsResult);
  }

  @override
  Future<Either<Failure, CurrentBookingDraftEntity>> getDraft() {
    draftCount += 1;
    return _answer(holdDraft, heldDraft, draftResult);
  }

  @override
  Future<Either<Failure, BookingDraftEntity>> saveDraft(
    SaveBookingDraftParamsEntity params,
  ) {
    saveDraftCalls.add(params);
    return _answer(holdSaveDraft, heldSaveDraft, saveDraftResult);
  }

  @override
  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  ) {
    createCalls.add(params);
    return _answer(holdCreate, heldCreate, createResult);
  }

  static Future<T> _answer<T>(bool hold, List<Completer<T>> held, T result) {
    if (!hold) {
      return Future<T>.value(result);
    }
    final Completer<T> completer = Completer<T>();
    held.add(completer);
    return completer.future;
  }
}

/// [BookingsMockLocal] with settable results that records every call. Set
/// [error] to make every call throw it.
final class FakeBookingsMockLocal implements BookingsMockLocal {
  Either<Failure, BookingEntity> bookingResult = Right<Failure, BookingEntity>(
    testBooking(),
  );
  Either<Failure, BookingEntity> cancelResult = Right<Failure, BookingEntity>(
    testBooking(status: BookingStatus.cancelled),
  );
  Either<Failure, List<BookingGuestEntity>> guestsResult =
      const Right<Failure, List<BookingGuestEntity>>(<BookingGuestEntity>[
        testAizhan,
      ]);
  Either<Failure, CurrentBookingDraftEntity> draftResult =
      Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft(testDraft()));
  Either<Failure, BookingDraftEntity> saveDraftResult =
      Right<Failure, BookingDraftEntity>(testDraft());
  Either<Failure, String> createResult = const Right<Failure, String>(
    'booking-1060',
  );

  Object? error;

  final List<String> bookingIds = <String>[];
  final List<String> cancelIds = <String>[];
  final List<String> guestQueries = <String>[];
  int draftCount = 0;
  final List<({SaveBookingDraftParamsEntity params, PropertyEntity property})>
  saveDraftCalls =
      <({SaveBookingDraftParamsEntity params, PropertyEntity property})>[];
  final List<CreateBookingParamsEntity> createCalls =
      <CreateBookingParamsEntity>[];

  @override
  Future<Either<Failure, BookingEntity>> loadBooking(String id) async {
    bookingIds.add(id);
    _throwIfSet();
    return bookingResult;
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) async {
    cancelIds.add(id);
    _throwIfSet();
    return cancelResult;
  }

  @override
  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(
    String query,
  ) async {
    guestQueries.add(query);
    _throwIfSet();
    return guestsResult;
  }

  @override
  Future<Either<Failure, CurrentBookingDraftEntity>> loadDraft() async {
    draftCount += 1;
    _throwIfSet();
    return draftResult;
  }

  @override
  Future<Either<Failure, BookingDraftEntity>> saveDraft({
    required SaveBookingDraftParamsEntity params,
    required PropertyEntity property,
  }) async {
    saveDraftCalls.add((params: params, property: property));
    _throwIfSet();
    return saveDraftResult;
  }

  @override
  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  ) async {
    createCalls.add(params);
    _throwIfSet();
    return createResult;
  }

  void _throwIfSet() {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
