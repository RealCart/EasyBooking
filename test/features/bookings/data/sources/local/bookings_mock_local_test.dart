import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/data/sources/local/bookings_mock_local.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

import '../../../../../helpers/fake_bookings_repository.dart';

const List<String> _knownIds = <String>[
  'booking-1039',
  'booking-1042',
  'booking-1044',
  'booking-1047',
  'booking-1051',
  'booking-1053',
  'booking-1058',
  'booking-1037',
  'booking-1036',
  'booking-1034',
  'booking-1046',
  'booking-1033',
  'booking-1028',
  'booking-1025',
  'booking-1019',
  'booking-1012',
  'booking-0964',
  'booking-0941',
  'booking-0918',
  'booking-0912',
];

/// A mock whose clock the test moves through [_Clock.now].
final class _Clock {
  _Clock([DateTime? start]) : now = start ?? bookingsTestNow;

  DateTime now;

  late final BookingsMockLocalImpl local = BookingsMockLocalImpl(
    now: () => now,
  );
}

/// [day] days after [bookingsTestNow]'s date, at [hour]:[minute].
DateTime _day(int day, int hour, [int minute = 0]) {
  return DateTime(
    bookingsTestNow.year,
    bookingsTestNow.month,
    bookingsTestNow.day + day,
    hour,
    minute,
  );
}

PropertyEntity _property({
  String id = 'esentai-city-84',
  String name = 'Esentai City',
  String unit = '84',
  int pricePerNight = 42500,
  List<String> channelNames = const <String>['Booking.com', 'Airbnb'],
}) {
  return PropertyEntity(
    id: id,
    name: name,
    unit: unit,
    city: 'Алматы',
    address: 'Аль-Фараби, 77/8',
    rooms: 2,
    areaSqm: 54,
    maxGuests: 4,
    pricePerNight: pricePerNight,
    imageUrls: const <String>[],
    channelNames: channelNames,
    syncedAt: bookingsTestNow,
    availability: PropertyAvailabilityEntity(
      kind: PropertyAvailabilityKind.freeUntil,
      at: bookingsTestNow,
    ),
    isFavorite: false,
    receivedAt: bookingsTestNow,
  );
}

SaveBookingDraftParamsEntity _draftParams({
  required DateTime checkIn,
  required DateTime checkOut,
  String propertyId = 'esentai-city-84',
  String phone = '+77001112233',
}) {
  return SaveBookingDraftParamsEntity(
    propertyId: propertyId,
    checkIn: checkIn,
    checkOut: checkOut,
    firstName: 'Ольга',
    lastName: 'Ким',
    phone: phone,
  );
}

CreateBookingParamsEntity _createParams(
  String draftId, {
  bool createContract = true,
  String? comment = 'Поздний заезд',
}) {
  return CreateBookingParamsEntity(
    draftId: draftId,
    totalPrice: 90000,
    deposit: 20000,
    source: BookingSource.krisha,
    createContract: createContract,
    comment: comment,
  );
}

T _right<T>(Either<Failure, T> result) {
  return switch (result) {
    Right<Failure, T>(:final T value) => value,
    Left<Failure, T>(:final Failure value) => throw TestFailure(
      'Expected a value, got $value',
    ),
  };
}

Failure _left<T>(Either<Failure, T> result) {
  return switch (result) {
    Left<Failure, T>(:final Failure value) => value,
    Right<Failure, T>(:final T value) => throw TestFailure(
      'Expected a failure, got $value',
    ),
  };
}

Future<BookingEntity> _load(BookingsMockLocal local, String id) async {
  return _right(await local.loadBooking(id));
}

Future<BookingDraftEntity> _saveDraft(
  BookingsMockLocal local, {
  required DateTime checkIn,
  required DateTime checkOut,
  PropertyEntity? property,
  String phone = '+77001112233',
}) async {
  final PropertyEntity target = property ?? _property();
  return _right(
    await local.saveDraft(
      params: _draftParams(
        propertyId: target.id,
        checkIn: checkIn,
        checkOut: checkOut,
        phone: phone,
      ),
      property: target,
    ),
  );
}

final Matcher _isNotFound = isA<ServerFailure>()
    .having((ServerFailure failure) => failure.statusCode, 'statusCode', 404)
    .having((ServerFailure failure) => failure.code, 'code', isNull);

void main() {
  group('BookingsMockLocalImpl.loadBooking', () {
    test('opens every known booking by its id', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      for (final String id in _knownIds) {
        expect((await _load(local, id)).id, id, reason: id);
      }
    });

    test('an unknown id or a bare number is a 404', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      for (final String id in <String>['1042', 'booking-9999', '']) {
        expect(_left(await local.loadBooking(id)), _isNotFound, reason: id);
      }
    });

    test('statuses follow the clock at 09:41', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      final Map<String, BookingStatus> expected = <String, BookingStatus>{
        // Checks in at 14:00 today.
        'booking-1042': BookingStatus.confirmed,
        // Checks out at 12:00 today.
        'booking-1039': BookingStatus.checkedIn,
        'booking-1037': BookingStatus.checkedIn,
        'booking-1034': BookingStatus.checkedIn,
        'booking-1046': BookingStatus.pending,
        'booking-1053': BookingStatus.pending,
        'booking-1051': BookingStatus.confirmed,
        'booking-1033': BookingStatus.cancelled,
        'booking-1019': BookingStatus.completed,
        'booking-0912': BookingStatus.completed,
      };
      for (final MapEntry<String, BookingStatus> entry in expected.entries) {
        expect(
          (await _load(local, entry.key)).status,
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('the same bookings move on later in the day', () async {
      final _Clock clock = _Clock();
      clock.now = _day(0, 15);

      expect(
        (await _load(clock.local, 'booking-1042')).status,
        BookingStatus.checkedIn,
      );
      expect(
        (await _load(clock.local, 'booking-1039')).status,
        BookingStatus.completed,
      );
      expect(
        (await _load(clock.local, 'booking-1053')).status,
        BookingStatus.pending,
      );
      expect(
        (await _load(clock.local, 'booking-1033')).status,
        BookingStatus.cancelled,
      );
    });

    test('dates are relative to the clock', () async {
      final BookingEntity booking = await _load(_Clock().local, 'booking-1042');

      expect(booking.checkIn, _day(0, 14));
      expect(booking.checkOut, _day(3, 12));
      expect(booking.nights, 3);
      expect(booking.totalPrice, 3 * 42500);
      expect(booking.contract?.id, 'eb-1048');
    });

    test('a loaded booking is stamped with the clock', () async {
      final _Clock clock = _Clock();

      expect(
        (await _load(clock.local, 'booking-1042')).receivedAt,
        bookingsTestNow,
      );

      clock.now = _day(0, 15);
      expect(
        (await _load(clock.local, 'booking-1042')).receivedAt,
        _day(0, 15),
      );
    });
  });

  group('BookingsMockLocalImpl.cancelBooking', () {
    test('cancels an upcoming booking and keeps it cancelled', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      final BookingEntity cancelled = _right(
        await local.cancelBooking('booking-1042'),
      );

      expect(cancelled.id, 'booking-1042');
      expect(cancelled.status, BookingStatus.cancelled);
      expect(
        (await _load(local, 'booking-1042')).status,
        BookingStatus.cancelled,
      );
    });

    test('cancels a booking whose guest is living in it', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      final BookingEntity cancelled = _right(
        await local.cancelBooking('booking-1037'),
      );

      expect(cancelled.status, BookingStatus.cancelled);
    });

    test('a cancelled booking stays cancelled when the clock moves', () async {
      final _Clock clock = _Clock();
      _right(await clock.local.cancelBooking('booking-1042'));

      clock.now = _day(0, 15);

      expect(
        (await _load(clock.local, 'booking-1042')).status,
        BookingStatus.cancelled,
      );
    });

    test(
      'a completed or already cancelled booking is not cancellable',
      () async {
        final BookingsMockLocalImpl local = _Clock().local;
        _right(await local.cancelBooking('booking-1042'));

        for (final String id in <String>[
          'booking-1019',
          'booking-1033',
          'booking-1042',
        ]) {
          expect(
            _left(await local.cancelBooking(id)),
            isA<ValidationFailure>().having(
              (ValidationFailure failure) => failure.code,
              'code',
              BookingErrorCodes.notCancellable,
            ),
            reason: id,
          );
        }
      },
    );

    test('an unknown booking is a 404', () async {
      expect(
        _left(await _Clock().local.cancelBooking('booking-9999')),
        _isNotFound,
      );
    });

    test('each instance keeps its own cancellations', () async {
      _right(await _Clock().local.cancelBooking('booking-1042'));

      expect(
        (await _load(_Clock().local, 'booking-1042')).status,
        BookingStatus.confirmed,
      );
    });
  });

  group('BookingsMockLocalImpl.searchGuests', () {
    test('matches names case-insensitively, once per phone', () async {
      final List<BookingGuestEntity> guests = _right(
        await _Clock().local.searchGuests('  айжАН '),
      );

      // Айжан has two bookings (1042 and 0912) with the same phone.
      expect(guests, <BookingGuestEntity>[testAizhan]);
    });

    test('matches the last name of several guests', () async {
      final List<BookingGuestEntity> guests = _right(
        await _Clock().local.searchGuests('Ахметова'),
      );

      expect(
        guests.map((BookingGuestEntity guest) => guest.fullName),
        unorderedEquals(<String>['Камила Ахметова', 'Гульнара Ахметова']),
      );
    });

    test('matches three or more phone digits in any format', () async {
      final List<BookingGuestEntity> guests = _right(
        await _Clock().local.searchGuests('245 18 92'),
      );

      expect(guests, <BookingGuestEntity>[testAizhan]);
    });

    test('fewer than three digits do not match phones', () async {
      expect(_right(await _Clock().local.searchGuests('70')), isEmpty);
    });

    test('a blank or unknown query finds nothing', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      expect(_right(await local.searchGuests('   ')), isEmpty);
      expect(_right(await local.searchGuests('Несуществующий')), isEmpty);
    });

    test('the result cannot be modified', () async {
      final List<BookingGuestEntity> guests = _right(
        await _Clock().local.searchGuests('Айжан'),
      );

      expect(() => guests.add(testDaniyar), throwsUnsupportedError);
    });
  });

  group('BookingsMockLocalImpl drafts', () {
    test('there is no draft at first', () async {
      expect(_right(await _Clock().local.loadDraft()).draft, isNull);
    });

    test('a draft read carries today from the clock, at midnight', () async {
      final _Clock clock = _Clock();

      expect(
        _right(await clock.local.loadDraft()).today,
        DateTime(2026, 10, 22),
      );

      clock.now = DateTime(2026, 10, 23, 0, 5);
      expect(
        _right(await clock.local.loadDraft()).today,
        DateTime(2026, 10, 23),
      );
    });

    test('saving quotes the property and keeps the draft', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );

      expect(draft.id, 'draft-1');
      expect(draft.propertyId, 'esentai-city-84');
      expect(draft.propertyName, 'Esentai City');
      expect(draft.unit, '84');
      expect(draft.checkIn, _day(20, 14));
      expect(draft.checkOut, _day(23, 12));
      expect(
        draft.guest,
        const BookingGuestEntity(
          firstName: 'Ольга',
          lastName: 'Ким',
          phone: '+77001112233',
        ),
      );
      expect(draft.suggestedTotalPrice, 3 * 42500);
      expect(draft.suggestedDeposit, BookingsMockLocalImpl.defaultDeposit);
      expect(draft.availability.checkedChannelNames, <String>[
        'Booking.com',
        'Airbnb',
      ]);
      expect(draft.availability.isAvailable, isTrue);
      expect(_right(await local.loadDraft()).draft, draft);
    });

    test('a new draft replaces the previous one', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      await _saveDraft(local, checkIn: _day(20, 14), checkOut: _day(23, 12));

      final BookingDraftEntity second = await _saveDraft(
        local,
        checkIn: _day(30, 14),
        checkOut: _day(31, 12),
      );

      expect(second.id, 'draft-2');
      expect(_right(await local.loadDraft()).draft, second);
    });

    test('overlapping dates list the conflicting bookings', () async {
      final BookingDraftEntity draft = await _saveDraft(
        _Clock().local,
        checkIn: _day(1, 14),
        checkOut: _day(4, 12),
      );

      // 1042 (today–+3), 1046 (+2–+5), and 1047 (+3–+6) in
      // Esentai City · 84.
      expect(
        draft.availability.conflictingBookingIds,
        unorderedEquals(<String>[
          'booking-1042',
          'booking-1046',
          'booking-1047',
        ]),
      );
      expect(draft.availability.isAvailable, isFalse);
    });

    test('conflicts are per apartment of a property', () async {
      // 1037 is in Samal Residence · 7 and 1044 in Samal Residence · 12;
      // both overlap tonight.
      final BookingDraftEntity draft = await _saveDraft(
        _Clock().local,
        property: _property(
          id: 'samal-residence',
          name: 'Samal Residence',
          unit: '7',
          pricePerNight: 38000,
        ),
        checkIn: _day(0, 20),
        checkOut: _day(1, 12),
      );

      expect(draft.availability.conflictingBookingIds, <String>[
        'booking-1037',
      ]);
    });

    test('cancelled bookings do not conflict', () async {
      final BookingsMockLocalImpl local = _Clock().local;

      // Only the stored cancelled booking 1033 overlaps these dates.
      final BookingDraftEntity pastDraft = await _saveDraft(
        local,
        checkIn: _day(-5, 15),
        checkOut: _day(-3, 12),
      );
      expect(pastDraft.availability.isAvailable, isTrue);

      _right(await local.cancelBooking('booking-1042'));
      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(0, 14),
        checkOut: _day(2, 12),
      );
      expect(draft.availability.isAvailable, isTrue);
    });

    test('touching dates do not conflict', () async {
      // 1042 checks in at 14:00 today, the moment this stay checks out.
      final BookingDraftEntity draft = await _saveDraft(
        _Clock().local,
        checkIn: _day(-1, 14),
        checkOut: _day(0, 14),
      );

      expect(draft.availability.isAvailable, isTrue);
    });
  });

  group('BookingsMockLocalImpl.createBooking', () {
    test('creates a pending unpaid booking and removes the draft', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );

      final String id = _right(
        await local.createBooking(_createParams(draft.id)),
      );

      expect(id, 'booking-1060');
      expect(_right(await local.loadDraft()).draft, isNull);
      final BookingEntity booking = await _load(local, id);
      expect(
        booking,
        BookingEntity(
          id: 'booking-1060',
          status: BookingStatus.pending,
          source: BookingSource.krisha,
          guest: draft.guest,
          propertyId: 'esentai-city-84',
          propertyName: 'Esentai City',
          unit: '84',
          checkIn: _day(20, 14),
          checkOut: _day(23, 12),
          totalPrice: 90000,
          deposit: 20000,
          isDepositPaid: false,
          isPaid: false,
          comment: 'Поздний заезд',
          contract: const BookingContractEntity(
            status: BookingContractStatus.draft,
          ),
          receivedAt: bookingsTestNow,
        ),
      );
    });

    test('without a contract the booking has none', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );

      final String id = _right(
        await local.createBooking(
          _createParams(draft.id, createContract: false, comment: null),
        ),
      );

      final BookingEntity booking = await _load(local, id);
      expect(booking.contract, isNull);
      expect(booking.comment, isNull);
    });

    test('the next booking gets the next number', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final BookingDraftEntity first = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );
      _right(await local.createBooking(_createParams(first.id)));
      final BookingDraftEntity second = await _saveDraft(
        local,
        checkIn: _day(30, 14),
        checkOut: _day(31, 12),
      );

      expect(
        _right(await local.createBooking(_createParams(second.id))),
        'booking-1061',
      );
    });

    test('a used, replaced, or missing draft is draft_not_found', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final Matcher draftNotFound = isA<ServerFailure>()
          .having((ServerFailure f) => f.statusCode, 'statusCode', 404)
          .having(
            (ServerFailure f) => f.code,
            'code',
            BookingErrorCodes.draftNotFound,
          );

      expect(
        _left(await local.createBooking(_createParams('draft-1'))),
        draftNotFound,
      );

      final BookingDraftEntity replaced = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );
      final BookingDraftEntity current = await _saveDraft(
        local,
        checkIn: _day(30, 14),
        checkOut: _day(31, 12),
      );
      expect(
        _left(await local.createBooking(_createParams(replaced.id))),
        draftNotFound,
      );

      _right(await local.createBooking(_createParams(current.id)));
      expect(
        _left(await local.createBooking(_createParams(current.id))),
        draftNotFound,
      );
    });

    test(
      'dates taken meanwhile are dates_unavailable; the draft stays',
      () async {
        final BookingsMockLocalImpl local = _Clock().local;
        final BookingDraftEntity first = await _saveDraft(
          local,
          checkIn: _day(20, 14),
          checkOut: _day(23, 12),
        );
        _right(await local.createBooking(_createParams(first.id)));
        final BookingDraftEntity overlapping = await _saveDraft(
          local,
          checkIn: _day(21, 14),
          checkOut: _day(22, 12),
        );
        expect(overlapping.availability.conflictingBookingIds, <String>[
          'booking-1060',
        ]);

        expect(
          _left(await local.createBooking(_createParams(overlapping.id))),
          isA<ValidationFailure>().having(
            (ValidationFailure failure) => failure.code,
            'code',
            BookingErrorCodes.datesUnavailable,
          ),
        );
        expect(_right(await local.loadDraft()).draft, overlapping);
      },
    );

    test('a created booking is found by guest search', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
        phone: '+77009998877',
      );
      expect(_right(await local.searchGuests('Ольга')), isEmpty);

      _right(await local.createBooking(_createParams(draft.id)));

      expect(_right(await local.searchGuests('Ольга')), <BookingGuestEntity>[
        draft.guest,
      ]);
    });

    test(
      'a created booking is restamped with the clock on every read',
      () async {
        final _Clock clock = _Clock();
        final BookingDraftEntity draft = await _saveDraft(
          clock.local,
          checkIn: _day(20, 14),
          checkOut: _day(23, 12),
        );
        final String id = _right(
          await clock.local.createBooking(_createParams(draft.id)),
        );

        clock.now = _day(1, 10);

        final BookingEntity booking = await _load(clock.local, id);
        expect(booking.status, BookingStatus.pending);
        expect(booking.receivedAt, _day(1, 10));
      },
    );

    test('a created booking becomes checkedIn, then completed', () async {
      final _Clock clock = _Clock();
      final BookingDraftEntity draft = await _saveDraft(
        clock.local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );
      final String id = _right(
        await clock.local.createBooking(_createParams(draft.id)),
      );

      clock.now = _day(21, 9);
      expect((await _load(clock.local, id)).status, BookingStatus.checkedIn);

      clock.now = _day(23, 12);
      expect((await _load(clock.local, id)).status, BookingStatus.completed);
      expect(
        _left(await clock.local.cancelBooking(id)),
        isA<ValidationFailure>(),
      );
    });

    test('a created booking can be cancelled before check-in', () async {
      final BookingsMockLocalImpl local = _Clock().local;
      final BookingDraftEntity draft = await _saveDraft(
        local,
        checkIn: _day(20, 14),
        checkOut: _day(23, 12),
      );
      final String id = _right(
        await local.createBooking(_createParams(draft.id)),
      );

      expect(
        _right(await local.cancelBooking(id)).status,
        BookingStatus.cancelled,
      );
      expect((await _load(local, id)).status, BookingStatus.cancelled);
    });
  });
}
