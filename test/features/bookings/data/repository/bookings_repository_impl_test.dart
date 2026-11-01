import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/data/repository/bookings_repository_impl.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

import '../../../../helpers/fake_bookings_repository.dart';
import '../../../../helpers/fake_properties_repository.dart';

const Failure _failure = ServerFailure(statusCode: 404, message: 'missing');

SaveBookingDraftParamsEntity _draftParams({String propertyId = 'p1'}) {
  return SaveBookingDraftParamsEntity(
    propertyId: propertyId,
    checkIn: DateTime(2026, 10, 28, 14),
    checkOut: DateTime(2026, 10, 31, 12),
    firstName: 'Айжан',
    lastName: 'Сарсенова',
    phone: '+77012451892',
  );
}

const CreateBookingParamsEntity _createParams = CreateBookingParamsEntity(
  draftId: 'draft-1',
  totalPrice: 127500,
  deposit: 50000,
  source: BookingSource.direct,
  createContract: true,
);

void main() {
  late FakeBookingsMockLocal local;
  late FakePropertiesRepository properties;
  late BookingsRepositoryImpl repository;

  setUp(() {
    local = FakeBookingsMockLocal();
    properties = FakePropertiesRepository();
    repository = BookingsRepositoryImpl(local: local, properties: properties);
  });

  group('BookingsRepositoryImpl', () {
    test('getBooking forwards the id and returns the source result', () async {
      final Either<Failure, BookingEntity> result = await repository.getBooking(
        'booking-1042',
      );

      expect(local.bookingIds, <String>['booking-1042']);
      expect(result, Right<Failure, BookingEntity>(testBooking()));
    });

    test(
      'cancelBooking forwards the id and returns the source result',
      () async {
        final Either<Failure, BookingEntity> result = await repository
            .cancelBooking('b1');

        expect(local.cancelIds, <String>['b1']);
        expect(
          result,
          Right<Failure, BookingEntity>(
            testBooking(status: BookingStatus.cancelled),
          ),
        );
      },
    );

    test('searchGuests forwards the query', () async {
      final Either<Failure, List<BookingGuestEntity>> result = await repository
          .searchGuests('Айж');

      expect(local.guestQueries, <String>['Айж']);
      expect(
        result.fold((_) => null, (List<BookingGuestEntity> guests) => guests),
        <BookingGuestEntity>[testAizhan],
      );
    });

    test('getDraft returns the source draft', () async {
      final Either<Failure, CurrentBookingDraftEntity> result = await repository
          .getDraft();

      expect(local.draftCount, 1);
      expect(
        result,
        Right<Failure, CurrentBookingDraftEntity>(
          testCurrentDraft(testDraft()),
        ),
      );
    });

    test('createBooking forwards the params and returns the id', () async {
      final Either<Failure, String> result = await repository.createBooking(
        _createParams,
      );

      expect(local.createCalls, <CreateBookingParamsEntity>[_createParams]);
      expect(result, const Right<Failure, String>('booking-1060'));
    });

    test('saveDraft passes the params with the looked-up property', () async {
      final Either<Failure, BookingDraftEntity> result = await repository
          .saveDraft(_draftParams());

      expect(result, Right<Failure, BookingDraftEntity>(testDraft()));
      expect(local.saveDraftCalls, hasLength(1));
      expect(local.saveDraftCalls.single.params, _draftParams());
      final PropertyEntity property = local.saveDraftCalls.single.property;
      expect(property.id, 'p1');
      expect(property, testProperties().first);
    });

    test('saveDraft fails on an unknown property before saving', () async {
      final Either<Failure, BookingDraftEntity> result = await repository
          .saveDraft(_draftParams(propertyId: 'missing'));

      expect(
        result,
        const Left<Failure, BookingDraftEntity>(
          ServerFailure(statusCode: 404),
        ),
      );
      expect(local.saveDraftCalls, isEmpty);
    });

    test('saveDraft passes a properties failure through unchanged', () async {
      properties.propertiesResult = const Left<Failure, List<PropertyEntity>>(
        ConnectionFailure(),
      );

      final Either<Failure, BookingDraftEntity> result = await repository
          .saveDraft(_draftParams());

      expect(
        result,
        const Left<Failure, BookingDraftEntity>(ConnectionFailure()),
      );
      expect(local.saveDraftCalls, isEmpty);
    });

    test('typed source failures pass through unchanged', () async {
      local
        ..bookingResult = const Left<Failure, BookingEntity>(_failure)
        ..cancelResult = const Left<Failure, BookingEntity>(_failure)
        ..guestsResult = const Left<Failure, List<BookingGuestEntity>>(
          _failure,
        )
        ..draftResult = const Left<Failure, CurrentBookingDraftEntity>(_failure)
        ..saveDraftResult = const Left<Failure, BookingDraftEntity>(_failure)
        ..createResult = const Left<Failure, String>(_failure);

      expect(
        await repository.getBooking('x'),
        const Left<Failure, BookingEntity>(_failure),
      );
      expect(
        await repository.cancelBooking('x'),
        const Left<Failure, BookingEntity>(_failure),
      );
      expect(
        await repository.searchGuests('x'),
        const Left<Failure, List<BookingGuestEntity>>(_failure),
      );
      expect(
        await repository.getDraft(),
        const Left<Failure, CurrentBookingDraftEntity>(_failure),
      );
      expect(
        await repository.saveDraft(_draftParams()),
        const Left<Failure, BookingDraftEntity>(_failure),
      );
      expect(
        await repository.createBooking(_createParams),
        const Left<Failure, String>(_failure),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getBooking('b1'), throwsStateError);
      await expectLater(repository.cancelBooking('b1'), throwsStateError);
      await expectLater(repository.searchGuests('a'), throwsStateError);
      await expectLater(repository.getDraft(), throwsStateError);
      await expectLater(repository.saveDraft(_draftParams()), throwsStateError);
      await expectLater(
        repository.createBooking(_createParams),
        throwsStateError,
      );
    });
  });
}
