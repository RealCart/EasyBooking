import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_file_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_stay_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';

/// Sample contracts until the contracts API exists. Guests, bookings,
/// properties, and contract ids match the guests, properties, calendar,
/// home, and notifications mocks.
///
/// Besides the seeded ids, `draft-<guest>` (for example `draft-arman`, as
/// returned by «Создать договор» on the guest screen) resolves to a new
/// draft for that guest's latest stay; it is created on first use.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Changes live in memory, so they last until
/// the app restarts. Replace it with a `ContractsRemote` returning models
/// when the endpoints are ready.
abstract interface class ContractsMockLocal {
  Future<Either<Failure, ContractEntity>> loadContract(String id);

  /// Expects validated, normalized params.
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  );

  /// Expects a validated, normalized address.
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  );
}

final class ContractsMockLocalImpl implements ContractsMockLocal {
  /// [now] supplies the current time, so the contracts are around today.
  ContractsMockLocalImpl({required this._now});

  /// Daniyar's contract for booking-1044: opened by the guest an hour ago,
  /// not signed. The home task «Договор Данияра» links to it.
  static const String daniyarOpenedId = 'eb-1052';

  /// Daniyar's new contract for the same booking, not sent yet. «Создать
  /// договор» on the guest screen links to it.
  static const String daniyarDraftId = 'samal-daniyar';

  static const String draftPrefix = 'draft-';

  static const String _signingUrlBase = 'https://easybooking.kz/sign/';

  /// The number of the first draft created through [draftPrefix].
  static const int _firstDraftNumber = 1054;

  static const _Property _esentai = _Property(
    id: 'esentai-city-84',
    name: 'Esentai City',
    unit: '84',
    pricePerNight: 42500,
  );
  static const _Property _megaTowers = _Property(
    id: 'mega-towers-126',
    name: 'Mega Towers',
    unit: '126',
    pricePerNight: 32000,
  );
  static const _Property _samal = _Property(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '12',
    pricePerNight: 38000,
  );
  static const _Property _samal7 = _Property(
    id: 'samal-residence',
    name: 'Samal Residence',
    unit: '7',
    pricePerNight: 38000,
  );
  static const _Property _highvill = _Property(
    id: 'highvill-5',
    name: 'Highvill',
    unit: '5',
    pricePerNight: 55000,
  );

  /// Guests by the key used in `draft-<key>`, with their latest stay. Names,
  /// phones, and stays match the guests mock.
  static const Map<String, _Guest> _guests = <String, _Guest>{
    'aizhan': _Guest(
      firstName: 'Айжан',
      lastName: 'Сарсенова',
      patronymic: 'Маратовна',
      iin: '970524400512',
      idNumber: '046318254',
      phone: '+77012451892',
      stay: _Stay(
        bookingId: 'booking-1042',
        property: _esentai,
        checkInDay: 0,
        checkInHour: 14,
        checkOutDay: 3,
        deposit: 50000,
      ),
    ),
    'daniyar': _Guest(
      firstName: 'Данияр',
      lastName: 'Муратов',
      patronymic: 'Ерланович',
      iin: '960312300214',
      idNumber: '048216721',
      phone: '+77003184521',
      stay: _Stay(
        bookingId: 'booking-1044',
        property: _samal,
        checkInDay: 0,
        checkInHour: 18,
        checkInMinute: 30,
        checkOutDay: 2,
        deposit: 40000,
      ),
    ),
    'arman': _Guest(
      firstName: 'Арман',
      lastName: 'Темирбек',
      patronymic: 'Нурланович',
      iin: '940817300631',
      idNumber: '043902517',
      phone: '+77056112784',
      stay: _Stay(
        bookingId: 'booking-1039',
        property: _megaTowers,
        checkInDay: -2,
        checkInHour: 15,
        checkOutDay: 0,
        deposit: 30000,
      ),
    ),
    'maria': _Guest(
      firstName: 'Мария',
      lastName: 'Жукова',
      patronymic: 'Андреевна',
      iin: '920209401187',
      idNumber: '039861445',
      phone: '+77019320617',
      stay: _Stay(
        bookingId: 'booking-0964',
        property: _esentai,
        checkInDay: -45,
        checkInHour: 14,
        checkOutDay: -41,
        deposit: 50000,
      ),
    ),
    'timur': _Guest(
      firstName: 'Тимур',
      lastName: 'Абенов',
      patronymic: 'Канатович',
      iin: '990603300845',
      idNumber: '052174386',
      phone: '+77472056390',
      stay: _Stay(
        bookingId: 'booking-1051',
        property: _megaTowers,
        checkInDay: 3,
        checkInHour: 15,
        checkOutDay: 5,
        deposit: 30000,
      ),
    ),
    'asel': _Guest(
      firstName: 'Асель',
      lastName: 'Нурланова',
      patronymic: 'Сериковна',
      iin: '980715400318',
      idNumber: '051734902',
      phone: '+77024187533',
      stay: _Stay(
        bookingId: 'booking-1037',
        property: _samal7,
        checkInDay: -2,
        checkInHour: 16,
        checkOutDay: 4,
        deposit: 50000,
      ),
    ),
    'madina': _Guest(
      firstName: 'Мадина',
      lastName: 'Касымова',
      patronymic: 'Болатовна',
      iin: '950128401962',
      idNumber: '047520318',
      phone: '+77085541246',
      stay: _Stay(
        bookingId: 'booking-1034',
        property: _highvill,
        checkInDay: -1,
        checkInHour: 15,
        checkOutDay: 2,
        deposit: 60000,
      ),
    ),
    'erlan': _Guest(
      firstName: 'Ерлан',
      lastName: 'Жумабеков',
      patronymic: 'Асқарович',
      iin: '880930300417',
      idNumber: '036294871',
      phone: '+77713902814',
      stay: _Stay(
        bookingId: 'booking-1028',
        property: _esentai,
        checkInDay: -9,
        checkInHour: 14,
        checkOutDay: -6,
        deposit: 50000,
      ),
    ),
    'kamila': _Guest(
      firstName: 'Камила',
      lastName: 'Ахметова',
      patronymic: 'Руслановна',
      iin: '000412600238',
      idNumber: '055063729',
      phone: '+77071268459',
      stay: _Stay(
        bookingId: 'booking-1019',
        property: _highvill,
        checkInDay: -20,
        checkInHour: 15,
        checkOutDay: -16,
        deposit: 60000,
      ),
    ),
    'ruslan': _Guest(
      firstName: 'Руслан',
      lastName: 'Ибраев',
      patronymic: 'Тимурович',
      iin: '910707300554',
      idNumber: '041187603',
      phone: '+77765039122',
      stay: _Stay(
        bookingId: 'booking-1012',
        property: _samal,
        checkInDay: -27,
        checkInHour: 14,
        checkOutDay: -24,
        deposit: 40000,
      ),
    ),
    'dina': _Guest(
      firstName: 'Дина',
      lastName: 'Ким',
      patronymic: 'Викторовна',
      iin: '930321401376',
      idNumber: '040658912',
      phone: '+77017784063',
      stay: _Stay(
        bookingId: 'booking-0941',
        property: _megaTowers,
        checkInDay: -60,
        checkInHour: 15,
        checkOutDay: -57,
        deposit: 30000,
      ),
    ),
    'sergey': _Guest(
      firstName: 'Сергей',
      lastName: 'Пак',
      patronymic: 'Олегович',
      iin: '870505300729',
      idNumber: '034571268',
      phone: '+77052491708',
      stay: _Stay(
        bookingId: 'booking-0918',
        property: _highvill,
        checkInDay: -75,
        checkInHour: 15,
        checkOutDay: -70,
        deposit: 60000,
      ),
    ),
  };

  /// Signed contracts: guest key and when the guest signed.
  static const List<_SignedSeed> _signedSeeds = <_SignedSeed>[
    _SignedSeed(number: 1048, guest: 'aizhan', day: -4, hour: 12, minute: 5),
    _SignedSeed(number: 1050, guest: 'timur', day: -1, hour: 16, minute: 40),
    // Matches the notification «Асель подписала договор» yesterday.
    _SignedSeed(number: 1049, guest: 'asel', day: -1, hour: 12, minute: 10),
    _SignedSeed(number: 1047, guest: 'madina', day: -2, hour: 10, minute: 30),
    _SignedSeed(number: 1040, guest: 'erlan', day: -11, hour: 10, minute: 20),
    _SignedSeed(number: 1033, guest: 'kamila', day: -22, hour: 18),
    _SignedSeed(number: 1031, guest: 'maria', day: -47, hour: 11, minute: 15),
    _SignedSeed(number: 1022, guest: 'dina', day: -62, hour: 14),
    _SignedSeed(number: 1015, guest: 'sergey', day: -77, hour: 16),
  ];

  final DateTime Function() _now;

  /// Built on first use, so relative dates are measured from that moment.
  Map<String, ContractEntity>? _contracts;

  /// Sends so far, to give each send a new link.
  int _sendCount = 0;

  int _nextDraftNumber = _firstDraftNumber;

  Map<String, ContractEntity> get _store => _contracts ??= _seed(_now());

  @override
  Future<Either<Failure, ContractEntity>> loadContract(String id) async {
    return _find(id).map(
      (ContractEntity contract) => contract.copyWith(receivedAt: _now()),
    );
  }

  @override
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  ) async {
    return _find(params.contractId).flatMap((ContractEntity contract) {
      if (contract.status.isSigned) {
        return const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.alreadySigned),
        );
      }
      final ContractGuestEntity guest = ContractGuestEntity(
        firstName: params.firstName,
        lastName: params.lastName,
        patronymic: params.patronymic.isEmpty ? null : params.patronymic,
        iin: params.iin,
        idNumber: params.idNumber,
        phone: contract.guest.phone,
      );
      // A sent link carries the old data, so changing it revokes the link.
      final bool revokesLink =
          guest != contract.guest && contract.status.isAwaitingSignature;
      final ContractEntity updated = contract.copyWith(
        guest: guest,
        status: revokesLink ? ContractStatus.draft : null,
        resetSigningUrl: revokesLink,
        resetRemindAt: revokesLink,
      );
      _store[contract.id] = updated;
      return Right<Failure, ContractEntity>(
        updated.copyWith(receivedAt: _now()),
      );
    });
  }

  @override
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  ) async {
    return _find(params.contractId).flatMap((ContractEntity contract) {
      if (contract.status.isSigned) {
        return const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.alreadySigned),
        );
      }
      final DateTime now = _now();
      final ContractRecipientEntity recipient = ContractRecipientEntity(
        channel: params.channel,
        address: params.address,
      );
      _sendCount++;
      final ContractEntity updated = contract.copyWith(
        status: ContractStatus.sent,
        recipient: recipient,
        history: List<ContractHistoryEntryEntity>.unmodifiable(
          <ContractHistoryEntryEntity>[
            ...contract.history,
            ContractHistoryEntryEntity(
              kind: ContractHistoryKind.sent,
              at: now,
              recipient: recipient,
            ),
          ],
        ),
        signingUrl: '$_signingUrlBase${contract.id}-$_sendCount',
        remindAt: now.add(const Duration(hours: 2)),
      );
      _store[contract.id] = updated;
      return Right<Failure, ContractEntity>(updated.copyWith(receivedAt: now));
    });
  }

  /// The contract [id]; a `draft-<guest>` id of a known guest creates the
  /// draft on first use.
  Either<Failure, ContractEntity> _find(String id) {
    final ContractEntity? contract = _store[id];
    if (contract != null) {
      return Right<Failure, ContractEntity>(contract);
    }
    final _Guest? guest = id.startsWith(draftPrefix)
        ? _guests[id.substring(draftPrefix.length)]
        : null;
    if (guest == null) {
      return Left<Failure, ContractEntity>(
        ServerFailure(statusCode: 404, message: 'Unknown contract $id'),
      );
    }
    final DateTime now = _now();
    final ContractEntity draft = _draft(
      id: id,
      number: _nextDraftNumber++,
      guest: guest,
      createdAt: now,
      now: now,
    );
    _store[id] = draft;
    return Right<Failure, ContractEntity>(draft);
  }

  static Map<String, ContractEntity> _seed(DateTime now) {
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    final _Guest daniyar = _guests['daniyar']!;
    final ContractRecipientEntity daniyarPhone = _smsTo(daniyar);
    // Matches the notification «Данияр открыл договор» an hour ago.
    final DateTime openedAt = now.subtract(const Duration(hours: 1));
    final DateTime sentAt = openedAt.subtract(const Duration(minutes: 9));

    return <String, ContractEntity>{
      daniyarOpenedId: _contract(
        id: daniyarOpenedId,
        number: 1052,
        guest: daniyar,
        status: ContractStatus.opened,
        history: <ContractHistoryEntryEntity>[
          ContractHistoryEntryEntity(
            kind: ContractHistoryKind.created,
            at: sentAt.subtract(const Duration(minutes: 18)),
          ),
          ContractHistoryEntryEntity(
            kind: ContractHistoryKind.sent,
            at: sentAt,
            recipient: daniyarPhone,
          ),
          ContractHistoryEntryEntity(
            kind: ContractHistoryKind.opened,
            at: openedAt,
          ),
        ],
        signingUrl: '$_signingUrlBase$daniyarOpenedId',
        remindAt: now.add(const Duration(hours: 2)),
        now: now,
      ),
      daniyarDraftId: _draft(
        id: daniyarDraftId,
        number: 1053,
        guest: daniyar,
        createdAt: now.subtract(const Duration(minutes: 5)),
        now: now,
      ),
      for (final _SignedSeed seed in _signedSeeds)
        seed.id: _signed(
          seed: seed,
          signedAt: at(seed.day, seed.hour, seed.minute),
          now: now,
        ),
    };
  }

  static ContractEntity _signed({
    required _SignedSeed seed,
    required DateTime signedAt,
    required DateTime now,
  }) {
    final _Guest guest = _guests[seed.guest]!;
    final DateTime sentAt = signedAt.subtract(const Duration(minutes: 50));
    return _contract(
      id: seed.id,
      number: seed.number,
      guest: guest,
      status: ContractStatus.signed,
      history: <ContractHistoryEntryEntity>[
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.created,
          at: sentAt.subtract(const Duration(minutes: 15)),
        ),
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.sent,
          at: sentAt,
          recipient: _smsTo(guest),
        ),
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.opened,
          at: signedAt.subtract(const Duration(minutes: 18)),
        ),
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.signed,
          at: signedAt,
        ),
      ],
      signingUrl: '$_signingUrlBase${seed.id}',
      now: now,
    );
  }

  static ContractEntity _draft({
    required String id,
    required int number,
    required _Guest guest,
    required DateTime createdAt,
    required DateTime now,
  }) {
    return _contract(
      id: id,
      number: number,
      guest: guest,
      status: ContractStatus.draft,
      history: <ContractHistoryEntryEntity>[
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.created,
          at: createdAt,
        ),
      ],
      now: now,
    );
  }

  static ContractEntity _contract({
    required String id,
    required int number,
    required _Guest guest,
    required ContractStatus status,
    required List<ContractHistoryEntryEntity> history,
    required DateTime now,
    String? signingUrl,
    DateTime? remindAt,
  }) {
    final _Stay stay = guest.stay;
    DateTime at(int dayOffset, int hour, [int minute = 0]) {
      return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
    }

    return ContractEntity(
      id: id,
      number: 'EB-$number',
      status: status,
      guest: ContractGuestEntity(
        firstName: guest.firstName,
        lastName: guest.lastName,
        patronymic: guest.patronymic,
        iin: guest.iin,
        idNumber: guest.idNumber,
        phone: guest.phone,
      ),
      identityDocument: const ContractFileEntity(
        name: 'Удостоверение.pdf',
        pageCount: 2,
        sizeBytes: 842 * 1024,
      ),
      isGuestDataRecognized: true,
      stay: ContractStayEntity(
        bookingId: stay.bookingId,
        propertyId: stay.property.id,
        propertyName: stay.property.name,
        unit: stay.property.unit,
        imageUrl: _imageOf(stay.property),
        checkIn: at(stay.checkInDay, stay.checkInHour, stay.checkInMinute),
        checkOut: at(stay.checkOutDay, 12),
        pricePerNight: stay.property.pricePerNight,
        deposit: stay.deposit,
      ),
      document: const ContractFileEntity(
        name: 'Договор найма',
        pageCount: 3,
        sizeBytes: 412 * 1024,
        language: 'русский язык',
      ),
      recipient: _smsTo(guest),
      history: List<ContractHistoryEntryEntity>.unmodifiable(history),
      signingUrl: signingUrl,
      remindAt: remindAt,
      receivedAt: now,
    );
  }

  static ContractRecipientEntity _smsTo(_Guest guest) {
    return ContractRecipientEntity(
      channel: ContractDeliveryChannel.sms,
      address: guest.phone,
    );
  }

  /// The same photos as the properties mock.
  static String _imageOf(_Property property) {
    return switch (property.id) {
      'esentai-city-84' => AppAssets.images.propertyLivingRoomWarm,
      'samal-residence' => AppAssets.images.propertyDiningRoom,
      _ => AppAssets.images.propertyLivingRoomBlue,
    };
  }
}

final class _Property {
  const _Property({
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

/// Day offsets are from today; check-out is at 12:00. Dates and the
/// deposit match the booking [bookingId] of the bookings mock.
final class _Stay {
  const _Stay({
    required this.bookingId,
    required this.property,
    required this.checkInDay,
    required this.checkInHour,
    required this.checkOutDay,
    required this.deposit,
    this.checkInMinute = 0,
  });

  final String bookingId;
  final _Property property;
  final int checkInDay;
  final int checkInHour;
  final int checkInMinute;
  final int checkOutDay;

  /// In whole tenge.
  final int deposit;
}

final class _Guest {
  const _Guest({
    required this.firstName,
    required this.lastName,
    required this.patronymic,
    required this.iin,
    required this.idNumber,
    required this.phone,
    required this.stay,
  });

  final String firstName;
  final String lastName;
  final String patronymic;
  final String iin;
  final String idNumber;

  /// E.164.
  final String phone;

  /// The latest stay, which a contract covers.
  final _Stay stay;
}

final class _SignedSeed {
  const _SignedSeed({
    required this.number,
    required this.guest,
    required this.day,
    required this.hour,
    this.minute = 0,
  });

  final int number;

  /// A key of `ContractsMockLocalImpl._guests`.
  final String guest;

  /// Day offset from today of the signature.
  final int day;
  final int hour;
  final int minute;

  String get id => 'eb-$number';
}
