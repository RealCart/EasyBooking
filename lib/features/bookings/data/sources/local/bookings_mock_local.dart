import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_availability_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// Sample bookings around today, until the bookings API exists.
///
/// The source of truth for stays: booking ids, guests, apartments, dates,
/// and contract ids of the calendar, properties, home, notifications,
/// guests, and contracts mocks match it. Check-in hours follow each
/// property's terms (15:00 in Mega Towers and Highvill), and contract send
/// times follow the history of the contracts mock.
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Cancellations, the draft, and created
/// bookings live in memory, so they last until the app restarts. Replace it
/// with a `BookingsRemote` returning models when the endpoints are ready.
abstract interface class BookingsMockLocal {
  Future<Either<Failure, BookingEntity>> loadBooking(String id);

  Future<Either<Failure, BookingEntity>> cancelBooking(String id);

  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(String query);

  /// The saved draft, if any, stamped with today from [BookingsMockLocalImpl]'s
  /// clock.
  Future<Either<Failure, CurrentBookingDraftEntity>> loadDraft();

  /// The mock has no property catalog, so the caller passes the [property]
  /// of `params.propertyId` for the quote; a server would look it up.
  Future<Either<Failure, BookingDraftEntity>> saveDraft({
    required SaveBookingDraftParamsEntity params,
    required PropertyEntity property,
  });

  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  );
}

final class BookingsMockLocalImpl implements BookingsMockLocal {
  /// [now] supplies the current time, so bookings are relative to today and
  /// their status follows the clock.
  BookingsMockLocalImpl({required this._now});

  /// The suggested deposit of a new booking, in whole tenge.
  static const int defaultDeposit = 50000;

  final DateTime Function() _now;

  final Set<String> _cancelledIds = <String>{};
  final List<BookingEntity> _created = <BookingEntity>[];
  BookingDraftEntity? _draft;
  int _nextBookingNumber = 1060;
  int _nextDraftNumber = 1;

  @override
  Future<Either<Failure, BookingEntity>> loadBooking(String id) async {
    final BookingEntity? booking = _find(id, _now());
    if (booking == null) {
      return Left<Failure, BookingEntity>(_unknownBooking(id));
    }
    return Right<Failure, BookingEntity>(booking);
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBooking(String id) async {
    final DateTime now = _now();
    final BookingEntity? booking = _find(id, now);
    if (booking == null) {
      return Left<Failure, BookingEntity>(_unknownBooking(id));
    }
    if (!booking.status.isCancellable) {
      return Left<Failure, BookingEntity>(
        ValidationFailure(
          code: BookingErrorCodes.notCancellable,
          message: 'Booking $id is ${booking.status.name}',
        ),
      );
    }
    _cancelledIds.add(id);
    return Right<Failure, BookingEntity>(_find(id, now) ?? booking);
  }

  @override
  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(
    String query,
  ) async {
    final String needle = query.trim().toLowerCase();
    final String digits = PhoneNumber.digitsOnly(needle);
    final Map<String, BookingGuestEntity> byPhone =
        <String, BookingGuestEntity>{
          for (final BookingEntity booking in _all(_now()))
            booking.guest.phone: booking.guest,
        };
    return Right<Failure, List<BookingGuestEntity>>(
      List<BookingGuestEntity>.unmodifiable(
        byPhone.values.where((BookingGuestEntity guest) {
          if (needle.isEmpty) {
            return false;
          }
          final bool nameMatches = guest.fullName.toLowerCase().contains(
            needle,
          );
          final bool phoneMatches =
              digits.length >= 3 &&
              PhoneNumber.digitsOnly(guest.phone).contains(digits);
          return nameMatches || phoneMatches;
        }),
      ),
    );
  }

  @override
  Future<Either<Failure, CurrentBookingDraftEntity>> loadDraft() async {
    return Right<Failure, CurrentBookingDraftEntity>(
      CurrentBookingDraftEntity(draft: _draft, today: _now().dateOnly),
    );
  }

  @override
  Future<Either<Failure, BookingDraftEntity>> saveDraft({
    required SaveBookingDraftParamsEntity params,
    required PropertyEntity property,
  }) async {
    final BookingDraftEntity draft = BookingDraftEntity(
      id: 'draft-${_nextDraftNumber++}',
      propertyId: property.id,
      propertyName: property.name,
      unit: property.unit,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guest: BookingGuestEntity(
        firstName: params.firstName,
        lastName: params.lastName,
        phone: params.phone,
      ),
      suggestedTotalPrice:
          params.checkIn.nightsUntil(params.checkOut) * property.pricePerNight,
      suggestedDeposit: defaultDeposit,
      availability: BookingAvailabilityEntity(
        checkedChannelNames: List<String>.unmodifiable(property.channelNames),
        conflictingBookingIds: _conflicts(
          propertyId: property.id,
          unit: property.unit,
          checkIn: params.checkIn,
          checkOut: params.checkOut,
        ),
      ),
    );
    _draft = draft;
    return Right<Failure, BookingDraftEntity>(draft);
  }

  @override
  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  ) async {
    final BookingDraftEntity? draft = _draft;
    if (draft == null || draft.id != params.draftId) {
      return Left<Failure, String>(
        ServerFailure(
          statusCode: 404,
          code: BookingErrorCodes.draftNotFound,
          message: 'Unknown draft ${params.draftId}',
        ),
      );
    }
    final List<String> conflicts = _conflicts(
      propertyId: draft.propertyId,
      unit: draft.unit,
      checkIn: draft.checkIn,
      checkOut: draft.checkOut,
    );
    if (conflicts.isNotEmpty) {
      return Left<Failure, String>(
        ValidationFailure(
          code: BookingErrorCodes.datesUnavailable,
          message: 'Dates overlap ${conflicts.join(', ')}',
        ),
      );
    }

    final String id = 'booking-${_nextBookingNumber++}';
    _created.add(
      BookingEntity(
        id: id,
        // Added by hand and not paid yet; becomes `checkedIn` and
        // `completed` with the clock.
        status: BookingStatus.pending,
        source: params.source,
        guest: draft.guest,
        propertyId: draft.propertyId,
        propertyName: draft.propertyName,
        unit: draft.unit,
        checkIn: draft.checkIn,
        checkOut: draft.checkOut,
        totalPrice: params.totalPrice,
        deposit: params.deposit,
        isDepositPaid: false,
        isPaid: false,
        comment: params.comment,
        contract: params.createContract
            ? const BookingContractEntity(status: BookingContractStatus.draft)
            : null,
        // Restamped by [_withStatus] on every read.
        receivedAt: _now(),
      ),
    );
    _draft = null;
    return Right<Failure, String>(id);
  }

  BookingEntity? _find(String id, DateTime now) {
    for (final BookingEntity booking in _all(now)) {
      if (booking.id == id) {
        return booking;
      }
    }
    return null;
  }

  /// Ids of the active bookings of the apartment that overlap the dates.
  ///
  /// The apartment is [propertyId] with [unit]: the sample data has two
  /// apartments in `samal-residence`.
  List<String> _conflicts({
    required String propertyId,
    required String unit,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return List<String>.unmodifiable(<String>[
      for (final BookingEntity booking in _all(_now()))
        if (booking.propertyId == propertyId &&
            booking.unit == unit &&
            booking.status != BookingStatus.cancelled &&
            booking.checkIn.isBefore(checkOut) &&
            checkIn.isBefore(booking.checkOut))
          booking.id,
    ]);
  }

  /// Every booking with its status at [now].
  List<BookingEntity> _all(DateTime now) {
    return <BookingEntity>[
      for (final BookingEntity booking in <BookingEntity>[
        ..._seed(now),
        ..._created,
      ])
        _withStatus(booking, now),
    ];
  }

  /// [booking] with its status at [now], stamped with [now] as its
  /// `receivedAt`: a stored or later cancellation stays, then `checkedIn`
  /// between check-in and check-out and `completed` after check-out; before
  /// check-in the stored status stays.
  BookingEntity _withStatus(BookingEntity booking, DateTime now) {
    final BookingStatus status =
        booking.status == BookingStatus.cancelled ||
            _cancelledIds.contains(booking.id)
        ? BookingStatus.cancelled
        : now.isBefore(booking.checkIn)
        ? booking.status
        : now.isBefore(booking.checkOut)
        ? BookingStatus.checkedIn
        : BookingStatus.completed;
    if (status == booking.status && now == booking.receivedAt) {
      return booking;
    }
    return BookingEntity(
      id: booking.id,
      status: status,
      source: booking.source,
      externalCode: booking.externalCode,
      guest: booking.guest,
      guestCount: booking.guestCount,
      propertyId: booking.propertyId,
      propertyName: booking.propertyName,
      unit: booking.unit,
      checkIn: booking.checkIn,
      checkOut: booking.checkOut,
      totalPrice: booking.totalPrice,
      deposit: booking.deposit,
      isDepositPaid: booking.isDepositPaid,
      isPaid: booking.isPaid,
      comment: booking.comment,
      contract: booking.contract,
      receivedAt: now,
    );
  }

  /// The sample bookings; the status is set by [_withStatus].
  List<BookingEntity> _seed(DateTime now) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    /// [id] is `null` for a contract no other mock defines.
    BookingContractEntity signed(String? id, DateTime sentAt, DateTime at) {
      return BookingContractEntity(
        id: id,
        status: BookingContractStatus.signed,
        sentAt: sentAt,
        signedAt: at,
      );
    }

    BookingEntity booking({
      required String id,
      required BookingSource source,
      required BookingGuestEntity guest,
      required _Apartment apartment,
      required DateTime checkIn,
      required DateTime checkOut,
      required int deposit,
      required bool isDepositPaid,
      required bool isPaid,
      BookingStatus status = BookingStatus.confirmed,
      int? guestCount,
      int? totalPrice,
      String? externalCode,
      String? comment,
      BookingContractEntity? contract,
    }) {
      return BookingEntity(
        id: id,
        status: status,
        source: source,
        externalCode: externalCode,
        guest: guest,
        guestCount: guestCount,
        propertyId: apartment.id,
        propertyName: apartment.name,
        unit: apartment.unit,
        checkIn: checkIn,
        checkOut: checkOut,
        totalPrice:
            totalPrice ??
            checkIn.nightsUntil(checkOut) * apartment.pricePerNight,
        deposit: deposit,
        isDepositPaid: isDepositPaid,
        isPaid: isPaid,
        comment: comment,
        contract: contract,
        receivedAt: now,
      );
    }

    return <BookingEntity>[
      booking(
        id: 'booking-1042',
        source: BookingSource.airbnb,
        externalCode: 'HM73P2',
        guest: _aizhan,
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(0, 14),
        checkOut: at(3, 12),
        deposit: 50000,
        isDepositPaid: false,
        isPaid: true,
        contract: signed('eb-1048', at(-4, 11, 15), at(-4, 12, 5)),
      ),
      booking(
        id: 'booking-1044',
        source: BookingSource.bookingCom,
        externalCode: '4127330918',
        guest: const BookingGuestEntity(
          firstName: 'Данияр',
          lastName: 'Муратов',
          phone: '+77003184521',
        ),
        guestCount: 3,
        apartment: _samal,
        checkIn: at(0, 18, 30),
        checkOut: at(2, 12),
        deposit: 40000,
        isDepositPaid: false,
        isPaid: false,
        comment: 'Уборка в 13:00 после выезда',
        contract: BookingContractEntity(
          id: 'eb-1052',
          status: BookingContractStatus.awaitingSignature,
          // Sent 9 minutes before the guest opened it an hour ago, as in
          // the contract's history.
          sentAt: now.subtract(const Duration(hours: 1, minutes: 9)),
        ),
      ),
      booking(
        id: 'booking-1039',
        source: BookingSource.airbnb,
        externalCode: 'HM58K1',
        guest: const BookingGuestEntity(
          firstName: 'Арман',
          lastName: 'Темирбек',
          phone: '+77056112784',
        ),
        guestCount: 2,
        apartment: _megaTowers,
        checkIn: at(-2, 15),
        checkOut: at(0, 12),
        deposit: 30000,
        isDepositPaid: true,
        isPaid: true,
        comment: 'Ключи оставит в сейфе',
      ),
      booking(
        id: 'booking-1051',
        source: BookingSource.airbnb,
        externalCode: 'HM91QX',
        guest: const BookingGuestEntity(
          firstName: 'Тимур',
          lastName: 'Абенов',
          phone: '+77472056390',
        ),
        guestCount: 1,
        apartment: _megaTowers,
        checkIn: at(3, 15),
        checkOut: at(5, 12),
        deposit: 30000,
        isDepositPaid: true,
        isPaid: false,
        comment: 'Ключи у консьержа',
        contract: signed('eb-1050', at(-1, 15, 50), at(-1, 16, 40)),
      ),
      booking(
        id: 'booking-1037',
        source: BookingSource.direct,
        guest: const BookingGuestEntity(
          firstName: 'Асель',
          lastName: 'Нурланова',
          phone: '+77024187533',
        ),
        guestCount: 2,
        apartment: _samal7,
        checkIn: at(-2, 16),
        checkOut: at(4, 12),
        deposit: 50000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1049', at(-1, 11, 20), at(-1, 12, 10)),
      ),
      booking(
        id: 'booking-1019',
        source: BookingSource.bookingCom,
        externalCode: '3870015523',
        guest: const BookingGuestEntity(
          firstName: 'Камила',
          lastName: 'Ахметова',
          phone: '+77071268459',
        ),
        guestCount: 3,
        apartment: _highvill,
        checkIn: at(-20, 15),
        checkOut: at(-16, 12),
        deposit: 60000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1033', at(-22, 17, 10), at(-22, 18)),
      ),
      booking(
        id: 'booking-1012',
        source: BookingSource.direct,
        guest: const BookingGuestEntity(
          firstName: 'Руслан',
          lastName: 'Ибраев',
          phone: '+77765039122',
        ),
        guestCount: 2,
        apartment: _samal,
        checkIn: at(-27, 14),
        checkOut: at(-24, 12),
        deposit: 40000,
        isDepositPaid: true,
        isPaid: true,
      ),
      booking(
        id: 'booking-0964',
        source: BookingSource.bookingCom,
        externalCode: '3981204476',
        guest: const BookingGuestEntity(
          firstName: 'Мария',
          lastName: 'Жукова',
          phone: '+77019320617',
        ),
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(-45, 14),
        checkOut: at(-41, 12),
        deposit: 50000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1031', at(-47, 10, 25), at(-47, 11, 15)),
      ),
      booking(
        id: 'booking-0941',
        source: BookingSource.airbnb,
        externalCode: 'HM6Z3R',
        guest: const BookingGuestEntity(
          firstName: 'Дина',
          lastName: 'Ким',
          phone: '+77017784063',
        ),
        guestCount: 1,
        apartment: _megaTowers,
        checkIn: at(-60, 15),
        checkOut: at(-57, 12),
        deposit: 30000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1022', at(-62, 13, 10), at(-62, 14)),
      ),
      booking(
        id: 'booking-0918',
        source: BookingSource.other,
        guest: const BookingGuestEntity(
          firstName: 'Сергей',
          lastName: 'Пак',
          phone: '+77052491708',
        ),
        guestCount: 2,
        apartment: _highvill,
        checkIn: at(-75, 15),
        checkOut: at(-70, 12),
        deposit: 60000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1015', at(-77, 15, 10), at(-77, 16)),
      ),
      booking(
        id: 'booking-0912',
        source: BookingSource.airbnb,
        externalCode: 'HM2K7D',
        guest: _aizhan,
        guestCount: 2,
        apartment: _megaTowers,
        checkIn: at(-106, 15),
        checkOut: at(-103, 12),
        deposit: 30000,
        isDepositPaid: true,
        isPaid: true,
      ),
      // Madina's stay of the guests and contracts mocks.
      booking(
        id: 'booking-1034',
        source: BookingSource.direct,
        guest: const BookingGuestEntity(
          firstName: 'Мадина',
          lastName: 'Касымова',
          phone: '+77085541246',
        ),
        guestCount: 2,
        apartment: _highvill,
        checkIn: at(-1, 15),
        checkOut: at(2, 12),
        deposit: 60000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1047', at(-2, 9, 40), at(-2, 10, 30)),
      ),
      // The hand-made booking of the Esentai conflict in the calendar sync
      // mock, created yesterday; it overlaps booking-1042 and booking-1047.
      booking(
        id: 'booking-1046',
        source: BookingSource.direct,
        status: BookingStatus.pending,
        guest: const BookingGuestEntity(
          firstName: 'Марат',
          lastName: 'Ильясов',
          phone: '+77055514230',
        ),
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(2, 14),
        checkOut: at(5, 12),
        totalPrice: 114000,
        deposit: 50000,
        isDepositPaid: false,
        isPaid: false,
      ),
      // Rows below match `_bookingsOf` of the properties mock.
      booking(
        id: 'booking-1047',
        source: BookingSource.bookingCom,
        externalCode: '4096617352',
        guest: const BookingGuestEntity(
          firstName: 'Олег',
          lastName: 'Беляев',
          phone: '+77012239087',
        ),
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(3, 14),
        checkOut: at(6, 12),
        totalPrice: 138000,
        deposit: 50000,
        isDepositPaid: false,
        isPaid: false,
        contract: BookingContractEntity(
          status: BookingContractStatus.awaitingSignature,
          sentAt: at(-1, 15, 20),
        ),
      ),
      booking(
        id: 'booking-1053',
        source: BookingSource.direct,
        status: BookingStatus.pending,
        guest: const BookingGuestEntity(
          firstName: 'Марат',
          lastName: 'Ильясов',
          phone: '+77055514230',
        ),
        guestCount: 3,
        apartment: _esentai,
        checkIn: at(6, 14),
        checkOut: at(9, 12),
        deposit: 50000,
        isDepositPaid: false,
        isPaid: false,
      ),
      booking(
        id: 'booking-1058',
        source: BookingSource.airbnb,
        externalCode: 'HM8C4N',
        guest: const BookingGuestEntity(
          firstName: 'Алина',
          lastName: 'Чехова',
          phone: '+77779043318',
        ),
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(11, 14),
        checkOut: at(15, 12),
        deposit: 50000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed(null, at(-2, 11), at(-2, 13, 25)),
      ),
      booking(
        id: 'booking-1036',
        source: BookingSource.bookingCom,
        externalCode: '3954870216',
        guest: const BookingGuestEntity(
          firstName: 'Гульнара',
          lastName: 'Ахметова',
          phone: '+77019467301',
        ),
        guestCount: 2,
        apartment: _samal,
        checkIn: at(-7, 14),
        checkOut: at(-4, 12),
        deposit: 40000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed(null, at(-9, 10), at(-9, 11, 40)),
      ),
      booking(
        id: 'booking-1033',
        source: BookingSource.bookingCom,
        externalCode: '3921558041',
        status: BookingStatus.cancelled,
        guest: const BookingGuestEntity(
          firstName: 'Ксения',
          lastName: 'Ли',
          phone: '+77015526174',
        ),
        guestCount: 1,
        apartment: _esentai,
        checkIn: at(-5, 15),
        checkOut: at(-3, 12),
        deposit: 0,
        isDepositPaid: false,
        isPaid: false,
      ),
      booking(
        id: 'booking-1028',
        source: BookingSource.airbnb,
        externalCode: 'HM4T8W',
        guest: const BookingGuestEntity(
          firstName: 'Ерлан',
          lastName: 'Жумабеков',
          phone: '+77713902814',
        ),
        guestCount: 2,
        apartment: _esentai,
        checkIn: at(-9, 14),
        checkOut: at(-6, 12),
        deposit: 50000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed('eb-1040', at(-11, 9, 30), at(-11, 10, 20)),
      ),
      booking(
        id: 'booking-1025',
        source: BookingSource.airbnb,
        externalCode: 'HM3V9L',
        guest: const BookingGuestEntity(
          firstName: 'Иван',
          lastName: 'Петров',
          phone: '+77012870445',
        ),
        guestCount: 5,
        apartment: _highvill,
        checkIn: at(-12, 15),
        checkOut: at(-9, 11),
        deposit: 60000,
        isDepositPaid: true,
        isPaid: true,
        contract: signed(null, at(-14, 12), at(-14, 12, 50)),
      ),
    ];
  }

  static ServerFailure _unknownBooking(String id) {
    return ServerFailure(statusCode: 404, message: 'Unknown booking $id');
  }

  static const BookingGuestEntity _aizhan = BookingGuestEntity(
    firstName: 'Айжан',
    lastName: 'Сарсенова',
    phone: '+77012451892',
  );

  static const _Apartment _esentai = _Apartment(
    id: 'esentai-city-84',
    name: 'Esentai City',
    unit: '84',
    pricePerNight: 42500,
  );
  static const _Apartment _megaTowers = _Apartment(
    id: 'mega-towers-126',
    name: 'Mega Towers',
    unit: '126',
    pricePerNight: 32000,
  );
  static const _Apartment _samal = _Apartment(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '12',
    pricePerNight: 38000,
  );
  static const _Apartment _samal7 = _Apartment(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '7',
    pricePerNight: 38000,
  );
  static const _Apartment _highvill = _Apartment(
    id: 'highvill-5',
    name: 'Highvill',
    unit: '5',
    pricePerNight: 55000,
  );
}

/// An apartment of the sample bookings, as in the properties mock.
final class _Apartment {
  const _Apartment({
    required this.id,
    required this.name,
    required this.unit,
    required this.pricePerNight,
  });

  final String id;
  final String name;
  final String unit;
  final int pricePerNight;
}
