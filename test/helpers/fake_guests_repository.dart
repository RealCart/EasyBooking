import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/data/sources/local/guests_mock_local.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_document_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_gender.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_summary_entity.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';

/// Thursday, 22 October 2026, 09:41, as in the design.
final DateTime guestsTestNow = DateTime(2026, 10, 22, 9, 41);

/// Айжан checks in to Esentai City · 84 today at 14:00 and stayed in Mega
/// Towers · 126 in July.
final GuestStayEntity testUpcomingStay = GuestStayEntity(
  bookingId: 'b1',
  propertyId: 'esentai-city-84',
  propertyName: 'Esentai City',
  unit: '84',
  checkIn: DateTime(2026, 10, 22, 14),
  checkOut: DateTime(2026, 10, 25, 12),
  status: GuestStayStatus.upcoming,
);

final GuestStayEntity testPastStay = GuestStayEntity(
  bookingId: 'b0',
  propertyId: 'mega-towers-126',
  propertyName: 'Mega Towers',
  unit: '126',
  checkIn: DateTime(2026, 7, 8, 15),
  checkOut: DateTime(2026, 7, 11, 12),
  status: GuestStayStatus.past,
);

/// `№ EB-1048`, signed on 18 October, of guest `g1`.
final GuestContractEntity testSignedContract = GuestContractEntity(
  id: 'c1',
  number: 'EB-1048',
  guestId: 'g1',
  guestName: 'Айжан Сарсенова',
  bookingId: 'b1',
  propertyId: 'esentai-city-84',
  propertyName: 'Esentai City',
  unit: '84',
  status: GuestContractStatus.signed,
  updatedAt: DateTime(2026, 10, 18, 12, 5),
);

/// `№ EB-1052`, opened by guest `g3` and awaiting a signature.
final GuestContractEntity testOpenedContract = GuestContractEntity(
  id: 'c2',
  number: 'EB-1052',
  guestId: 'g3',
  guestName: 'Данияр Муратов',
  bookingId: 'b3',
  propertyId: 'samal-residence',
  propertyName: 'Samal Residence',
  unit: '12',
  status: GuestContractStatus.opened,
  updatedAt: DateTime(2026, 10, 22, 8, 41),
);

/// Guest `g1` with a verified ID card, two stays, and one signed contract.
GuestEntity testGuest({
  String id = 'g1',
  List<GuestStayEntity>? stays,
  List<GuestContractEntity>? contracts,
}) {
  return GuestEntity(
    id: id,
    fullName: 'Айжан Сарсенова',
    phone: '+7 701 245 18 92',
    gender: GuestGender.female,
    document: GuestDocumentEntity(
      kind: GuestDocumentKind.idCard,
      status: GuestDocumentStatus.verified,
      updatedAt: DateTime(2026, 10, 18, 11, 20),
    ),
    stays: stays ?? <GuestStayEntity>[testUpcomingStay, testPastStay],
    contracts: contracts ?? <GuestContractEntity>[testSignedContract],
  );
}

/// Айжан (`g1`, checks in today, signed) and Арман (`g2`, checked out
/// yesterday, no contract), and the contracts [testOpenedContract] and
/// [testSignedContract]; 12 guests in all.
GuestDirectoryEntity testGuestDirectory({
  String query = '',
  List<GuestSummaryEntity>? guests,
  List<GuestContractEntity>? contracts,
}) {
  return GuestDirectoryEntity(
    query: query,
    guests:
        guests ??
        <GuestSummaryEntity>[
          GuestSummaryEntity(
            id: 'g1',
            fullName: 'Айжан Сарсенова',
            phone: '+7 701 245 18 92',
            gender: GuestGender.female,
            latestStay: testUpcomingStay,
            latestContractStatus: GuestContractStatus.signed,
          ),
          GuestSummaryEntity(
            id: 'g2',
            fullName: 'Арман Темирбек',
            phone: '+7 705 611 27 84',
            gender: GuestGender.male,
            latestStay: GuestStayEntity(
              bookingId: 'b2',
              propertyId: 'mega-towers-126',
              propertyName: 'Mega Towers',
              unit: '126',
              checkIn: DateTime(2026, 10, 19, 15),
              checkOut: DateTime(2026, 10, 21, 12),
              status: GuestStayStatus.past,
            ),
          ),
        ],
    contracts:
        contracts ??
        <GuestContractEntity>[testOpenedContract, testSignedContract],
    totalGuestCount: 12,
    receivedAt: guestsTestNow,
  );
}

/// [GuestsRepository] with settable results that records every call.
///
/// Set a `hold...` flag to keep the next requests of that kind pending;
/// each gets a completer in the matching `held...` list.
final class FakeGuestsRepository implements GuestsRepository {
  Either<Failure, GuestDirectoryEntity> directoryResult =
      Right<Failure, GuestDirectoryEntity>(testGuestDirectory());
  Either<Failure, GuestEntity> guestResult = Right<Failure, GuestEntity>(
    testGuest(),
  );
  Either<Failure, String> createContractResult = const Right<Failure, String>(
    'draft-g1',
  );

  bool holdDirectory = false;
  bool holdGuest = false;
  bool holdCreateContract = false;

  final List<Completer<Either<Failure, GuestDirectoryEntity>>> heldDirectory =
      <Completer<Either<Failure, GuestDirectoryEntity>>>[];
  final List<Completer<Either<Failure, GuestEntity>>> heldGuest =
      <Completer<Either<Failure, GuestEntity>>>[];
  final List<Completer<Either<Failure, String>>> heldCreateContract =
      <Completer<Either<Failure, String>>>[];

  final List<String> directoryQueries = <String>[];
  final List<String> guestIds = <String>[];
  final List<String> createContractIds = <String>[];

  @override
  Future<Either<Failure, GuestDirectoryEntity>> getDirectory(String query) {
    directoryQueries.add(query);
    return _answer(holdDirectory, heldDirectory, directoryResult);
  }

  @override
  Future<Either<Failure, GuestEntity>> getGuest(String id) {
    guestIds.add(id);
    return _answer(holdGuest, heldGuest, guestResult);
  }

  @override
  Future<Either<Failure, String>> createContract(String guestId) {
    createContractIds.add(guestId);
    return _answer(
      holdCreateContract,
      heldCreateContract,
      createContractResult,
    );
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

/// [GuestsMockLocal] with settable results that records every call. Set
/// [error] to make every call throw it.
final class FakeGuestsMockLocal implements GuestsMockLocal {
  Either<Failure, GuestDirectoryEntity> directoryResult =
      Right<Failure, GuestDirectoryEntity>(testGuestDirectory());
  Either<Failure, GuestEntity> guestResult = Right<Failure, GuestEntity>(
    testGuest(),
  );
  Either<Failure, String> createContractResult = const Right<Failure, String>(
    'draft-g1',
  );

  Object? error;

  final List<String> directoryQueries = <String>[];
  final List<String> guestIds = <String>[];
  final List<String> createContractIds = <String>[];

  @override
  Future<Either<Failure, GuestDirectoryEntity>> loadDirectory(
    String query,
  ) async {
    directoryQueries.add(query);
    _throwIfSet();
    return directoryResult;
  }

  @override
  Future<Either<Failure, GuestEntity>> loadGuest(String id) async {
    guestIds.add(id);
    _throwIfSet();
    return guestResult;
  }

  @override
  Future<Either<Failure, String>> createContract(String guestId) async {
    createContractIds.add(guestId);
    _throwIfSet();
    return createContractResult;
  }

  void _throwIfSet() {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
