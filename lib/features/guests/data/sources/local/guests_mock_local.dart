import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_document_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_gender.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';

/// Twelve sample guests until the guests API exists. Stays match the
/// bookings mock; booking, property, and contract ids match the home,
/// calendar, properties, contracts, and notifications mocks.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. It matches search queries itself, as the
/// server will. Replace it with a `GuestsRemote` returning models when the
/// endpoints are ready.
abstract interface class GuestsMockLocal {
  /// Recent guests for an empty [query], otherwise every match, plus the
  /// matching contracts.
  Future<Either<Failure, GuestDirectoryEntity>> loadDirectory(String query);

  Future<Either<Failure, GuestEntity>> loadGuest(String id);

  /// The id of the contract draft for [guestId]; the same id every time.
  Future<Either<Failure, String>> createContract(String guestId);
}

final class GuestsMockLocalImpl implements GuestsMockLocal {
  /// [now] supplies the current time, so stays are around today.
  const GuestsMockLocalImpl({required this._now});

  static const String aizhanId = 'guest-aizhan';
  static const String daniyarId = 'guest-daniyar';
  static const String armanId = 'guest-arman';
  static const String mariaId = 'guest-maria';
  static const String timurId = 'guest-timur';
  static const String aselId = 'guest-asel';
  static const String madinaId = 'guest-madina';
  static const String erlanId = 'guest-erlan';
  static const String kamilaId = 'guest-kamila';
  static const String ruslanId = 'guest-ruslan';
  static const String dinaId = 'guest-dina';
  static const String sergeyId = 'guest-sergey';

  /// Daniyar's unsent draft, returned by «Создать договор» on his guest
  /// screen. The home task «Договор Данияра» opens his sent contract eb-1052.
  static const String daniyarDraftContractId = 'samal-daniyar';

  /// How many guests «Недавние гости» shows for an empty query.
  static const int _recentCount = 4;

  static const _Property _esentai = _Property(
    id: 'esentai-city-84',
    name: 'Esentai City',
    unit: '84',
  );
  static const _Property _megaTowers = _Property(
    id: 'mega-towers-126',
    name: 'Mega Towers',
    unit: '126',
  );
  static const _Property _samal = _Property(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '12',
  );
  static const _Property _samal7 = _Property(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '7',
  );
  static const _Property _highvill = _Property(
    id: 'highvill-5',
    name: 'Highvill',
    unit: '5',
  );

  final DateTime Function() _now;

  @override
  Future<Either<Failure, GuestDirectoryEntity>> loadDirectory(
    String query,
  ) async {
    final DateTime now = _now();
    final List<GuestEntity> guests = _guests(now);
    final String needle = query.trim().toLowerCase();

    final List<GuestEntity> shown = needle.isEmpty
        ? guests.take(_recentCount).toList()
        : guests
              .where((GuestEntity guest) => _guestMatches(guest, needle))
              .toList();

    final List<GuestContractEntity> contracts = <GuestContractEntity>[
      for (final GuestEntity guest in guests)
        for (final GuestContractEntity contract in guest.contracts)
          if (needle.isEmpty || _contractMatches(contract, needle)) contract,
    ]..sort(_compareContracts);

    return Right<Failure, GuestDirectoryEntity>(
      GuestDirectoryEntity(
        query: query.trim(),
        guests: List<GuestSummaryEntity>.unmodifiable(shown.map(_summaryOf)),
        contracts: List<GuestContractEntity>.unmodifiable(contracts),
        totalGuestCount: guests.length,
        receivedAt: now,
      ),
    );
  }

  @override
  Future<Either<Failure, GuestEntity>> loadGuest(String id) async {
    for (final GuestEntity guest in _guests(_now())) {
      if (guest.id == id) {
        return Right<Failure, GuestEntity>(guest);
      }
    }
    return Left<Failure, GuestEntity>(_unknownGuest(id));
  }

  @override
  Future<Either<Failure, String>> createContract(String guestId) async {
    if (!_allIds.contains(guestId)) {
      return Left<Failure, String>(_unknownGuest(guestId));
    }
    if (guestId == daniyarId) {
      return const Right<Failure, String>(daniyarDraftContractId);
    }
    return Right<Failure, String>(
      'draft-${guestId.replaceFirst('guest-', '')}',
    );
  }

  static const Set<String> _allIds = <String>{
    aizhanId,
    daniyarId,
    armanId,
    mariaId,
    timurId,
    aselId,
    madinaId,
    erlanId,
    kamilaId,
    ruslanId,
    dinaId,
    sergeyId,
  };

  static Failure _unknownGuest(String id) {
    return ServerFailure(statusCode: 404, message: 'Unknown guest $id');
  }

  /// Every guest, most recent activity first; the first four are the ones
  /// in the design.
  List<GuestEntity> _guests(DateTime now) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    GuestStayEntity stay(
      String bookingId,
      _Property property,
      DateTime checkIn,
      DateTime checkOut,
    ) {
      return GuestStayEntity(
        bookingId: bookingId,
        propertyId: property.id,
        propertyName: property.name,
        unit: property.unit,
        checkIn: checkIn,
        checkOut: checkOut,
        status: _statusOf(checkIn, checkOut, now),
      );
    }

    GuestEntity guest({
      required String id,
      required String fullName,
      required String phone,
      required GuestGender gender,
      required List<GuestStayEntity> stays,
      required List<_ContractSeed> contracts,
      GuestDocumentEntity? document,
    }) {
      return GuestEntity(
        id: id,
        fullName: fullName,
        phone: phone,
        gender: gender,
        document: document,
        stays: List<GuestStayEntity>.unmodifiable(stays),
        contracts: List<GuestContractEntity>.unmodifiable(
          contracts.map(
            (_ContractSeed seed) => GuestContractEntity(
              id: seed.id,
              number: seed.number,
              guestId: id,
              guestName: fullName,
              bookingId: seed.stay.bookingId,
              propertyId: seed.stay.propertyId,
              propertyName: seed.stay.propertyName,
              unit: seed.stay.unit,
              status: seed.status,
              updatedAt: seed.updatedAt,
            ),
          ),
        ),
      );
    }

    GuestDocumentEntity verifiedId(DateTime verifiedAt) {
      return GuestDocumentEntity(
        kind: GuestDocumentKind.idCard,
        status: GuestDocumentStatus.verified,
        updatedAt: verifiedAt,
      );
    }

    final GuestStayEntity aizhanNow = stay(
      'booking-1042',
      _esentai,
      at(0, 14),
      at(3, 12),
    );
    final GuestStayEntity daniyarNow = stay(
      'booking-1044',
      _samal,
      at(0, 18, 30),
      at(2, 12),
    );
    final GuestStayEntity mariaStay = stay(
      'booking-0964',
      _esentai,
      at(-45, 14),
      at(-41, 12),
    );
    final GuestStayEntity timurStay = stay(
      'booking-1051',
      _megaTowers,
      at(3, 15),
      at(5, 12),
    );
    final GuestStayEntity aselStay = stay(
      'booking-1037',
      _samal7,
      at(-2, 16),
      at(4, 12),
    );
    final GuestStayEntity madinaStay = stay(
      'booking-1034',
      _highvill,
      at(-1, 15),
      at(2, 12),
    );
    final GuestStayEntity erlanStay = stay(
      'booking-1028',
      _esentai,
      at(-9, 14),
      at(-6, 12),
    );
    final GuestStayEntity kamilaStay = stay(
      'booking-1019',
      _highvill,
      at(-20, 15),
      at(-16, 12),
    );
    final GuestStayEntity dinaStay = stay(
      'booking-0941',
      _megaTowers,
      at(-60, 15),
      at(-57, 12),
    );
    final GuestStayEntity sergeyStay = stay(
      'booking-0918',
      _highvill,
      at(-75, 15),
      at(-70, 12),
    );

    return <GuestEntity>[
      guest(
        id: aizhanId,
        fullName: 'Айжан Сарсенова',
        phone: '+7 701 245 18 92',
        gender: GuestGender.female,
        document: verifiedId(at(-4, 11, 20)),
        stays: <GuestStayEntity>[
          aizhanNow,
          stay('booking-0912', _megaTowers, at(-106, 15), at(-103, 12)),
        ],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1048',
            number: 'EB-1048',
            stay: aizhanNow,
            status: GuestContractStatus.signed,
            updatedAt: at(-4, 12, 5),
          ),
        ],
      ),
      guest(
        id: daniyarId,
        fullName: 'Данияр Муратов',
        phone: '+7 700 318 45 21',
        gender: GuestGender.male,
        document: GuestDocumentEntity(
          kind: GuestDocumentKind.idCard,
          status: GuestDocumentStatus.pending,
          updatedAt: at(-1, 20, 15),
        ),
        stays: <GuestStayEntity>[daniyarNow],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1052',
            number: 'EB-1052',
            stay: daniyarNow,
            status: GuestContractStatus.opened,
            updatedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      guest(
        id: armanId,
        fullName: 'Арман Темирбек',
        phone: '+7 705 611 27 84',
        gender: GuestGender.male,
        stays: <GuestStayEntity>[
          stay('booking-1039', _megaTowers, at(-2, 15), at(0, 12)),
        ],
        contracts: const <_ContractSeed>[],
      ),
      guest(
        id: mariaId,
        fullName: 'Мария Жукова',
        phone: '+7 701 932 06 17',
        gender: GuestGender.female,
        document: GuestDocumentEntity(
          kind: GuestDocumentKind.passport,
          status: GuestDocumentStatus.verified,
          updatedAt: at(-47, 10, 40),
        ),
        stays: <GuestStayEntity>[mariaStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1031',
            number: 'EB-1031',
            stay: mariaStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-47, 11, 15),
          ),
        ],
      ),
      guest(
        id: timurId,
        fullName: 'Тимур Абенов',
        phone: '+7 747 205 63 90',
        gender: GuestGender.male,
        document: verifiedId(at(-1, 16, 30)),
        stays: <GuestStayEntity>[timurStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1050',
            number: 'EB-1050',
            stay: timurStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-1, 16, 40),
          ),
        ],
      ),
      guest(
        id: aselId,
        fullName: 'Асель Нурланова',
        phone: '+7 702 418 75 33',
        gender: GuestGender.female,
        document: verifiedId(at(-3, 19, 5)),
        stays: <GuestStayEntity>[aselStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1049',
            number: 'EB-1049',
            stay: aselStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-1, 12, 10),
          ),
        ],
      ),
      guest(
        id: madinaId,
        fullName: 'Мадина Касымова',
        phone: '+7 708 554 12 46',
        gender: GuestGender.female,
        document: verifiedId(at(-2, 10, 10)),
        stays: <GuestStayEntity>[madinaStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1047',
            number: 'EB-1047',
            stay: madinaStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-2, 10, 30),
          ),
        ],
      ),
      guest(
        id: erlanId,
        fullName: 'Ерлан Жумабеков',
        phone: '+7 771 390 28 14',
        gender: GuestGender.male,
        document: verifiedId(at(-11, 9, 50)),
        stays: <GuestStayEntity>[erlanStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1040',
            number: 'EB-1040',
            stay: erlanStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-11, 10, 20),
          ),
        ],
      ),
      guest(
        id: kamilaId,
        fullName: 'Камила Ахметова',
        phone: '+7 707 126 84 59',
        gender: GuestGender.female,
        document: verifiedId(at(-22, 17, 40)),
        stays: <GuestStayEntity>[kamilaStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1033',
            number: 'EB-1033',
            stay: kamilaStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-22, 18),
          ),
        ],
      ),
      guest(
        id: ruslanId,
        fullName: 'Руслан Ибраев',
        phone: '+7 776 503 91 22',
        gender: GuestGender.male,
        stays: <GuestStayEntity>[
          stay('booking-1012', _samal, at(-27, 14), at(-24, 12)),
        ],
        contracts: const <_ContractSeed>[],
      ),
      guest(
        id: dinaId,
        fullName: 'Дина Ким',
        phone: '+7 701 778 40 63',
        gender: GuestGender.female,
        document: GuestDocumentEntity(
          kind: GuestDocumentKind.passport,
          status: GuestDocumentStatus.verified,
          updatedAt: at(-62, 13, 25),
        ),
        stays: <GuestStayEntity>[dinaStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1022',
            number: 'EB-1022',
            stay: dinaStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-62, 14),
          ),
        ],
      ),
      guest(
        id: sergeyId,
        fullName: 'Сергей Пак',
        phone: '+7 705 249 17 08',
        gender: GuestGender.male,
        document: verifiedId(at(-77, 15, 30)),
        stays: <GuestStayEntity>[sergeyStay],
        contracts: <_ContractSeed>[
          _ContractSeed(
            id: 'eb-1015',
            number: 'EB-1015',
            stay: sergeyStay,
            status: GuestContractStatus.signed,
            updatedAt: at(-77, 16),
          ),
        ],
      ),
    ];
  }

  static GuestStayStatus _statusOf(
    DateTime checkIn,
    DateTime checkOut,
    DateTime now,
  ) {
    if (!now.isBefore(checkOut)) {
      return GuestStayStatus.past;
    }
    if (!now.isBefore(checkIn)) {
      return GuestStayStatus.current;
    }
    return GuestStayStatus.upcoming;
  }

  static GuestSummaryEntity _summaryOf(GuestEntity guest) {
    return GuestSummaryEntity(
      id: guest.id,
      fullName: guest.fullName,
      phone: guest.phone,
      gender: guest.gender,
      latestStay: guest.stays.isEmpty ? null : guest.stays.first,
      latestContractStatus: guest.contracts.isEmpty
          ? null
          : guest.contracts.first.status,
    );
  }

  /// [needle] is trimmed and lower case. Digits also match the phone
  /// regardless of its spaces.
  static bool _guestMatches(GuestEntity guest, String needle) {
    if (guest.fullName.toLowerCase().contains(needle)) {
      return true;
    }
    // Only a phone-like query searches phones: the digits of "Samal 7" would
    // otherwise match every +7 number.
    final bool isPhoneQuery = RegExp(r'^[\d\s+()-]+$').hasMatch(needle);
    final String digits = needle.replaceAll(RegExp(r'\D'), '');
    if (isPhoneQuery &&
        digits.isNotEmpty &&
        guest.phone.replaceAll(RegExp(r'\D'), '').contains(digits)) {
      return true;
    }
    return guest.stays.any(
      (GuestStayEntity stay) =>
          '${stay.propertyName} ${stay.unit}'.toLowerCase().contains(needle),
    );
  }

  static bool _contractMatches(GuestContractEntity contract, String needle) {
    return '${contract.guestName} ${contract.number} '
            '${contract.propertyName} ${contract.unit}'
        .toLowerCase()
        .contains(needle);
  }

  /// Awaiting a signature first, then the newest.
  static int _compareContracts(GuestContractEntity a, GuestContractEntity b) {
    if (a.status.isAwaitingSignature != b.status.isAwaitingSignature) {
      return a.status.isAwaitingSignature ? -1 : 1;
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }
}

final class _Property {
  const _Property({required this.id, required this.name, required this.unit});

  final String id;
  final String name;
  final String unit;
}

/// A contract before the guest's id and name are filled in.
final class _ContractSeed {
  const _ContractSeed({
    required this.id,
    required this.number,
    required this.stay,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String number;
  final GuestStayEntity stay;
  final GuestContractStatus status;
  final DateTime updatedAt;
}
