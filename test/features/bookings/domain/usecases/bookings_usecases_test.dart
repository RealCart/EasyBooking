import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/cancel_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/get_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/search_booking_guests_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/save_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/search_booking_guests_usecase.dart';

import '../../../../helpers/fake_bookings_repository.dart';

const Failure _failure = ServerFailure(statusCode: 500, code: 'boom');

SaveBookingDraftParamsEntity _draftParams({
  String propertyId = 'p1',
  DateTime? checkIn,
  DateTime? checkOut,
  String firstName = 'Айжан',
  String lastName = 'Сарсенова',
  String phone = '+7 701 245 18 92',
}) {
  return SaveBookingDraftParamsEntity(
    propertyId: propertyId,
    checkIn: checkIn ?? DateTime(2026, 10, 28, 14),
    checkOut: checkOut ?? DateTime(2026, 10, 31, 12),
    firstName: firstName,
    lastName: lastName,
    phone: phone,
  );
}

CreateBookingParamsEntity _createParams({
  int totalPrice = 127500,
  int deposit = 50000,
  BookingSource source = BookingSource.direct,
  String? comment,
  bool createContract = true,
}) {
  return CreateBookingParamsEntity(
    draftId: 'draft-1',
    totalPrice: totalPrice,
    deposit: deposit,
    source: source,
    comment: comment,
    createContract: createContract,
  );
}

Map<String, String> _fieldErrors(Either<Failure, Object?> result) {
  return switch (result) {
    Left<Failure, Object?>(value: final ValidationFailure failure) =>
      failure.fieldErrors,
    _ => throw TestFailure('Expected a ValidationFailure, got $result'),
  };
}

void main() {
  late FakeBookingsRepository repository;

  setUp(() => repository = FakeBookingsRepository());

  group('GetBookingUsecase', () {
    test('forwards the id and returns the booking', () async {
      final Either<Failure, BookingEntity> result = await GetBookingUsecase(
        repository,
      )(const GetBookingParamsEntity(bookingId: 'booking-1042'));

      expect(repository.bookingIds, <String>['booking-1042']);
      expect(result, Right<Failure, BookingEntity>(testBooking()));
    });

    test('passes a failure through unchanged', () async {
      repository.bookingResult = const Left<Failure, BookingEntity>(_failure);

      final Either<Failure, BookingEntity> result = await GetBookingUsecase(
        repository,
      )(const GetBookingParamsEntity(bookingId: 'x'));

      expect(result, const Left<Failure, BookingEntity>(_failure));
    });
  });

  group('CancelBookingUsecase', () {
    test('forwards the id and returns the cancelled booking', () async {
      final Either<Failure, BookingEntity> result = await CancelBookingUsecase(
        repository,
      )(const CancelBookingParamsEntity(bookingId: 'b1'));

      expect(repository.cancelIds, <String>['b1']);
      expect(
        result,
        Right<Failure, BookingEntity>(
          testBooking(status: BookingStatus.cancelled),
        ),
      );
    });

    test('passes a not-cancellable failure through unchanged', () async {
      const Failure notCancellable = ValidationFailure(
        code: BookingErrorCodes.notCancellable,
      );
      repository.cancelResult = const Left<Failure, BookingEntity>(
        notCancellable,
      );

      final Either<Failure, BookingEntity> result = await CancelBookingUsecase(
        repository,
      )(const CancelBookingParamsEntity(bookingId: 'b1'));

      expect(result, const Left<Failure, BookingEntity>(notCancellable));
    });
  });

  group('SearchBookingGuestsUsecase', () {
    test('forwards the trimmed query and returns the guests', () async {
      final Either<Failure, List<BookingGuestEntity>> result =
          await SearchBookingGuestsUsecase(
            repository,
          )(const SearchBookingGuestsParamsEntity(query: '  Айж  '));

      expect(repository.guestQueries, <String>['Айж']);
      expect(result.isRight, isTrue);
      expect(
        result.fold((_) => null, (List<BookingGuestEntity> guests) => guests),
        <BookingGuestEntity>[testAizhan],
      );
    });

    test('a blank query finds nothing and sends no request', () async {
      final Either<Failure, List<BookingGuestEntity>> result =
          await SearchBookingGuestsUsecase(
            repository,
          )(const SearchBookingGuestsParamsEntity(query: ' \t '));

      expect(repository.guestQueries, isEmpty);
      expect(
        result.fold((_) => null, (List<BookingGuestEntity> guests) => guests),
        isEmpty,
      );
    });

    test('passes a failure through unchanged', () async {
      repository.guestsResult = const Left<Failure, List<BookingGuestEntity>>(
        _failure,
      );

      final Either<Failure, List<BookingGuestEntity>> result =
          await SearchBookingGuestsUsecase(
            repository,
          )(const SearchBookingGuestsParamsEntity(query: 'x'));

      expect(result, const Left<Failure, List<BookingGuestEntity>>(_failure));
    });
  });

  group('GetBookingDraftUsecase', () {
    test('returns the saved draft', () async {
      repository.draftResult = Right<Failure, CurrentBookingDraftEntity>(
        testCurrentDraft(testDraft()),
      );

      final Either<Failure, CurrentBookingDraftEntity> result =
          await GetBookingDraftUsecase(repository)(const NoParams());

      expect(repository.draftCount, 1);
      expect(
        result,
        Right<Failure, CurrentBookingDraftEntity>(
          testCurrentDraft(testDraft()),
        ),
      );
    });

    test('returns null when there is no draft', () async {
      final Either<Failure, CurrentBookingDraftEntity> result =
          await GetBookingDraftUsecase(repository)(const NoParams());

      expect(
        result,
        Right<Failure, CurrentBookingDraftEntity>(testCurrentDraft()),
      );
    });

    test('passes a failure through unchanged', () async {
      repository.draftResult = const Left<Failure, CurrentBookingDraftEntity>(
        _failure,
      );

      final Either<Failure, CurrentBookingDraftEntity> result =
          await GetBookingDraftUsecase(repository)(const NoParams());

      expect(result, const Left<Failure, CurrentBookingDraftEntity>(_failure));
    });
  });

  group('SaveBookingDraftUsecase', () {
    late SaveBookingDraftUsecase usecase;

    setUp(() => usecase = SaveBookingDraftUsecase(repository));

    test('trims the names and sends the phone in E.164', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(
          propertyId: ' p1 ',
          firstName: '  Айжан ',
          lastName: ' Сарсенова  ',
          phone: '8 (701) 245-18-92',
        ),
      );

      expect(result, Right<Failure, BookingDraftEntity>(testDraft()));
      expect(repository.saveDraftCalls, <SaveBookingDraftParamsEntity>[
        SaveBookingDraftParamsEntity(
          propertyId: 'p1',
          checkIn: DateTime(2026, 10, 28, 14),
          checkOut: DateTime(2026, 10, 31, 12),
          firstName: 'Айжан',
          lastName: 'Сарсенова',
          phone: '+77012451892',
        ),
      ]);
    });

    test('accepts an empty last name', () async {
      await usecase(_draftParams(lastName: '   '));

      expect(repository.saveDraftCalls.single.lastName, '');
    });

    test(
      'accepts exactly one night even with an earlier check-out hour',
      () async {
        await usecase(
          _draftParams(
            checkIn: DateTime(2026, 10, 28, 14),
            checkOut: DateTime(2026, 10, 29, 12),
          ),
        );

        expect(repository.saveDraftCalls, hasLength(1));
      },
    );

    test('a missing property is required', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(propertyId: '  '),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.property: BookingErrorCodes.required,
      });
      expect(repository.saveDraftCalls, isEmpty);
    });

    test('a check-out on the check-in day is rejected', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(
          checkIn: DateTime(2026, 10, 28, 10),
          checkOut: DateTime(2026, 10, 28, 22),
        ),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.checkOut: BookingErrorCodes.checkOutBeforeCheckIn,
      });
      expect(repository.saveDraftCalls, isEmpty);
    });

    test('a check-out before check-in is rejected', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(
          checkIn: DateTime(2026, 10, 28, 14),
          checkOut: DateTime(2026, 10, 26, 12),
        ),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.checkOut: BookingErrorCodes.checkOutBeforeCheckIn,
      });
    });

    test('a blank first name is required', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(firstName: '   '),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.firstName: BookingErrorCodes.required,
      });
      expect(repository.saveDraftCalls, isEmpty);
    });

    test('a blank phone is required', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(phone: '  '),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.phone: BookingErrorCodes.required,
      });
      expect(repository.saveDraftCalls, isEmpty);
    });

    test('an incomplete or foreign phone is invalid', () async {
      for (final String phone in <String>[
        '+7 701 245 18',
        '+7 601 245 18 92',
        '+1 202 555 0143',
      ]) {
        final Either<Failure, BookingDraftEntity> result = await usecase(
          _draftParams(phone: phone),
        );

        expect(_fieldErrors(result), <String, String>{
          BookingFields.phone: BookingErrorCodes.invalidPhone,
        }, reason: phone);
      }
      expect(repository.saveDraftCalls, isEmpty);
    });

    test('reports every broken rule at once', () async {
      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(
          propertyId: '',
          checkOut: DateTime(2026, 10, 28, 20),
          firstName: '',
          phone: '123',
        ),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.property: BookingErrorCodes.required,
        BookingFields.checkOut: BookingErrorCodes.checkOutBeforeCheckIn,
        BookingFields.firstName: BookingErrorCodes.required,
        BookingFields.phone: BookingErrorCodes.invalidPhone,
      });
    });

    test('passes a repository failure through unchanged', () async {
      repository.saveDraftResult = const Left<Failure, BookingDraftEntity>(
        _failure,
      );

      final Either<Failure, BookingDraftEntity> result = await usecase(
        _draftParams(),
      );

      expect(result, const Left<Failure, BookingDraftEntity>(_failure));
    });
  });

  group('CreateBookingUsecase', () {
    late CreateBookingUsecase usecase;

    setUp(() => usecase = CreateBookingUsecase(repository));

    test('forwards the params and returns the new booking id', () async {
      final Either<Failure, String> result = await usecase(
        _createParams(source: BookingSource.krisha, createContract: false),
      );

      expect(result, const Right<Failure, String>('booking-1060'));
      expect(repository.createCalls, <CreateBookingParamsEntity>[
        _createParams(source: BookingSource.krisha, createContract: false),
      ]);
    });

    test('accepts a zero deposit and every manual source', () async {
      for (final BookingSource source in BookingSource.manual) {
        await usecase(_createParams(deposit: 0, source: source));
      }

      expect(repository.createCalls, hasLength(3));
    });

    test('trims the comment and turns a blank one into null', () async {
      await usecase(_createParams(comment: '  Поздний заезд  '));
      await usecase(_createParams(comment: '  \n '));

      expect(repository.createCalls[0].comment, 'Поздний заезд');
      expect(repository.createCalls[1].comment, isNull);
    });

    test('a total of zero or less is an invalid amount', () async {
      for (final int total in <int>[0, -1]) {
        final Either<Failure, String> result = await usecase(
          _createParams(totalPrice: total),
        );

        expect(_fieldErrors(result), <String, String>{
          BookingFields.totalPrice: BookingErrorCodes.invalidAmount,
        }, reason: '$total');
      }
      expect(repository.createCalls, isEmpty);
    });

    test('a negative deposit is an invalid amount', () async {
      final Either<Failure, String> result = await usecase(
        _createParams(deposit: -1),
      );

      expect(_fieldErrors(result), <String, String>{
        BookingFields.deposit: BookingErrorCodes.invalidAmount,
      });
      expect(repository.createCalls, isEmpty);
    });

    test('a channel source is unsupported', () async {
      for (final BookingSource source in <BookingSource>[
        BookingSource.airbnb,
        BookingSource.bookingCom,
      ]) {
        final Either<Failure, String> result = await usecase(
          _createParams(source: source),
        );

        expect(_fieldErrors(result), <String, String>{
          BookingFields.source: BookingErrorCodes.unsupportedSource,
        }, reason: source.name);
      }
      expect(repository.createCalls, isEmpty);
    });

    test('passes a repository failure through unchanged', () async {
      const Failure unavailable = ValidationFailure(
        code: BookingErrorCodes.datesUnavailable,
      );
      repository.createResult = const Left<Failure, String>(unavailable);

      final Either<Failure, String> result = await usecase(_createParams());

      expect(result, const Left<Failure, String>(unavailable));
    });
  });
}
