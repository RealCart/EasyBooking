import 'dart:async';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_file_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_stay_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';

/// Thursday, 22 October 2026, 09:41, as in the design.
final DateTime contractsTestNow = DateTime(2026, 10, 22, 9, 41);

/// Данияр Муратов, the guest of every test contract.
const ContractGuestEntity testContractGuest = ContractGuestEntity(
  firstName: 'Данияр',
  lastName: 'Муратов',
  patronymic: 'Ерланович',
  iin: '960312300214',
  idNumber: '048216721',
  phone: '+77003184521',
);

/// The guest's phone by SMS.
const ContractRecipientEntity testSmsRecipient = ContractRecipientEntity(
  channel: ContractDeliveryChannel.sms,
  address: '+77003184521',
);

/// The signing link of a sent test contract.
const String testSigningUrl = 'https://easybooking.kz/sign/c1-1';

/// Samal Residence · 12, 22–24 октября (2 nights), 38 000 ₸ per night.
ContractStayEntity testContractStay() {
  return ContractStayEntity(
    bookingId: 'booking-1044',
    propertyId: 'samal-residence',
    propertyName: 'Samal Residence',
    unit: '12',
    imageUrl: AppAssets.images.propertyDiningRoom,
    checkIn: DateTime(2026, 10, 22, 18, 30),
    checkOut: DateTime(2026, 10, 24, 12),
    pricePerNight: 38000,
    deposit: 50000,
  );
}

/// Contract `c1` (№ EB-1053), created today at 09:36. A draft by default.
ContractEntity testContract({
  String id = 'c1',
  ContractStatus status = ContractStatus.draft,
  ContractGuestEntity guest = testContractGuest,
  ContractRecipientEntity recipient = testSmsRecipient,
  List<ContractHistoryEntryEntity>? history,
  String? signingUrl,
  DateTime? remindAt,
}) {
  return ContractEntity(
    id: id,
    number: 'EB-1053',
    status: status,
    guest: guest,
    identityDocument: const ContractFileEntity(
      name: 'Удостоверение.pdf',
      pageCount: 2,
      sizeBytes: 842 * 1024,
    ),
    isGuestDataRecognized: true,
    stay: testContractStay(),
    document: const ContractFileEntity(
      name: 'Договор найма',
      pageCount: 3,
      sizeBytes: 412 * 1024,
      language: 'русский язык',
    ),
    recipient: recipient,
    history:
        history ??
        <ContractHistoryEntryEntity>[
          ContractHistoryEntryEntity(
            kind: ContractHistoryKind.created,
            at: DateTime(2026, 10, 22, 9, 36),
          ),
        ],
    signingUrl: signingUrl,
    remindAt: remindAt,
    receivedAt: contractsTestNow,
  );
}

/// [testContract] sent by SMS at 09:40, with a reminder in two hours.
ContractEntity testSentContract({String id = 'c1'}) {
  return testContract(
    id: id,
    status: ContractStatus.sent,
    history: <ContractHistoryEntryEntity>[
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.created,
        at: DateTime(2026, 10, 22, 9, 36),
      ),
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.sent,
        at: DateTime(2026, 10, 22, 9, 40),
        recipient: testSmsRecipient,
      ),
    ],
    signingUrl: testSigningUrl,
    remindAt: contractsTestNow.add(const Duration(hours: 2)),
  );
}

/// [testContract] signed yesterday at 12:10.
ContractEntity testSignedContract({String id = 'c1'}) {
  return testContract(
    id: id,
    status: ContractStatus.signed,
    history: <ContractHistoryEntryEntity>[
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.created,
        at: DateTime(2026, 10, 21, 11, 5),
      ),
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.sent,
        at: DateTime(2026, 10, 21, 11, 20),
        recipient: testSmsRecipient,
      ),
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.opened,
        at: DateTime(2026, 10, 21, 11, 52),
      ),
      ContractHistoryEntryEntity(
        kind: ContractHistoryKind.signed,
        at: DateTime(2026, 10, 21, 12, 10),
      ),
    ],
    signingUrl: testSigningUrl,
  );
}

/// [ContractsRepository] with configurable results that records calls.
///
/// Set [holdGet], [holdUpdate], or [holdSend] to keep the next requests of
/// that kind pending; each gets a completer in the matching `held*` list.
/// Set [error] to make every method throw it.
final class FakeContractsRepository implements ContractsRepository {
  Either<Failure, ContractEntity> getResult = Right<Failure, ContractEntity>(
    testContract(),
  );
  Either<Failure, ContractEntity> updateResult = Right<Failure, ContractEntity>(
    testContract(),
  );
  Either<Failure, ContractEntity> sendResult = Right<Failure, ContractEntity>(
    testSentContract(),
  );
  Object? error;

  bool holdGet = false;
  bool holdUpdate = false;
  bool holdSend = false;
  final List<Completer<Either<Failure, ContractEntity>>> heldGets =
      <Completer<Either<Failure, ContractEntity>>>[];
  final List<Completer<Either<Failure, ContractEntity>>> heldUpdates =
      <Completer<Either<Failure, ContractEntity>>>[];
  final List<Completer<Either<Failure, ContractEntity>>> heldSends =
      <Completer<Either<Failure, ContractEntity>>>[];

  final List<String> getCalls = <String>[];
  final List<UpdateContractGuestParamsEntity> updateCalls =
      <UpdateContractGuestParamsEntity>[];
  final List<SendContractParamsEntity> sendCalls = <SendContractParamsEntity>[];

  @override
  Future<Either<Failure, ContractEntity>> getContract(String id) {
    getCalls.add(id);
    return _answer(getResult, hold: holdGet, held: heldGets);
  }

  @override
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  ) {
    updateCalls.add(params);
    return _answer(updateResult, hold: holdUpdate, held: heldUpdates);
  }

  @override
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  ) {
    sendCalls.add(params);
    return _answer(sendResult, hold: holdSend, held: heldSends);
  }

  Future<Either<Failure, ContractEntity>> _answer(
    Either<Failure, ContractEntity> result, {
    required bool hold,
    required List<Completer<Either<Failure, ContractEntity>>> held,
  }) async {
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
    if (!hold) {
      return result;
    }
    final Completer<Either<Failure, ContractEntity>> completer =
        Completer<Either<Failure, ContractEntity>>();
    held.add(completer);
    return completer.future;
  }
}
