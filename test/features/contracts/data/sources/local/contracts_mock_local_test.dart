import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/data/sources/local/contracts_mock_local.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';

import '../../../../../helpers/fake_contracts_repository.dart';

const List<String> _signedIds = <String>[
  'eb-1048',
  'eb-1050',
  'eb-1049',
  'eb-1047',
  'eb-1040',
  'eb-1033',
  'eb-1031',
  'eb-1022',
  'eb-1015',
];

/// The mock with a clock that tests can move.
final class _Subject {
  DateTime now = contractsTestNow;
  late final ContractsMockLocalImpl local = ContractsMockLocalImpl(
    now: () => now,
  );

  Future<ContractEntity> load(String id) async {
    return _right(await local.loadContract(id));
  }

  Future<Either<Failure, ContractEntity>> update(
    String id, {
    String firstName = 'Данияр',
    String lastName = 'Муратов',
    String patronymic = 'Ерланович',
    String iin = '960312300214',
    String idNumber = '048216721',
  }) {
    return local.updateGuest(
      UpdateContractGuestParamsEntity(
        contractId: id,
        firstName: firstName,
        lastName: lastName,
        patronymic: patronymic,
        iin: iin,
        idNumber: idNumber,
      ),
    );
  }

  Future<Either<Failure, ContractEntity>> send(
    String id, {
    ContractDeliveryChannel channel = ContractDeliveryChannel.whatsApp,
    String address = '+77011234567',
  }) {
    return local.sendContract(
      SendContractParamsEntity(
        contractId: id,
        channel: channel,
        address: address,
      ),
    );
  }
}

ContractEntity _right(Either<Failure, ContractEntity> result) {
  return switch (result) {
    Right<Failure, ContractEntity>(:final ContractEntity value) => value,
    Left<Failure, ContractEntity>(:final Failure value) => throw TestFailure(
      'Expected a contract, got $value',
    ),
  };
}

Failure _left(Either<Failure, ContractEntity> result) {
  return switch (result) {
    Left<Failure, ContractEntity>(:final Failure value) => value,
    Right<Failure, ContractEntity>(:final ContractEntity value) =>
      throw TestFailure('Expected a failure, got $value'),
  };
}

Matcher get _isNotFound => isA<ServerFailure>().having(
  (ServerFailure failure) => failure.statusCode,
  'statusCode',
  404,
);

void main() {
  group('ContractsMockLocalImpl.loadContract', () {
    test('eb-1052 was opened by Данияр an hour ago and is unsigned', () async {
      final ContractEntity contract = await _Subject().load('eb-1052');

      expect(contract.number, 'EB-1052');
      expect(contract.status, ContractStatus.opened);
      expect(contract.guest.fullName, 'Данияр Муратов');
      expect(
        contract.history.map((ContractHistoryEntryEntity e) => e.kind),
        <ContractHistoryKind>[
          ContractHistoryKind.created,
          ContractHistoryKind.sent,
          ContractHistoryKind.opened,
        ],
      );
      expect(contract.history.last.at, DateTime(2026, 10, 22, 8, 41));
      expect(contract.history[1].recipient, testSmsRecipient);
      expect(contract.signingUrl, 'https://easybooking.kz/sign/eb-1052');
      expect(contract.remindAt, DateTime(2026, 10, 22, 11, 41));
      expect(contract.receivedAt, contractsTestNow);
    });

    test('samal-daniyar is a draft created five minutes ago', () async {
      final ContractEntity contract = await _Subject().load('samal-daniyar');

      expect(contract.number, 'EB-1053');
      expect(contract.status, ContractStatus.draft);
      expect(contract.history, <ContractHistoryEntryEntity>[
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.created,
          at: DateTime(2026, 10, 22, 9, 36),
        ),
      ]);
      expect(contract.signingUrl, isNull);
      expect(contract.remindAt, isNull);
      expect(contract.recipient, testSmsRecipient);
    });

    test('the Samal stay is today 18:30 to the 24th, two nights', () async {
      final ContractEntity contract = await _Subject().load('samal-daniyar');

      expect(contract.stay.bookingId, 'booking-1044');
      expect(contract.stay.propertyName, 'Samal Residence');
      expect(contract.stay.unit, '12');
      expect(contract.stay.checkIn, DateTime(2026, 10, 22, 18, 30));
      expect(contract.stay.checkOut, DateTime(2026, 10, 24, 12));
      expect(contract.stay.nights, 2);
      expect(contract.stay.rentTotal, 76000);
    });

    for (final String id in _signedIds) {
      test('$id is signed with no reminder', () async {
        final ContractEntity contract = await _Subject().load(id);

        expect(contract.id, id);
        expect(contract.number, 'EB-${id.substring(3)}');
        expect(contract.status, ContractStatus.signed);
        expect(contract.history.last.kind, ContractHistoryKind.signed);
        expect(contract.remindAt, isNull);
        expect(contract.signingUrl, isNotNull);
      });
    }

    test('eb-1049 was signed yesterday at 12:10', () async {
      final ContractEntity contract = await _Subject().load('eb-1049');

      expect(contract.guest.fullName, 'Асель Нурланова');
      expect(contract.history.last.at, DateTime(2026, 10, 21, 12, 10));
    });

    test('the history is unmodifiable', () async {
      final ContractEntity contract = await _Subject().load('eb-1052');

      expect(
        () => contract.history.add(contract.history.first),
        throwsUnsupportedError,
      );
    });

    for (final String id in <String>['missing', 'draft-nobody', 'draft-', '']) {
      test('"$id" is a 404 ServerFailure', () async {
        expect(_left(await _Subject().local.loadContract(id)), _isNotFound);
      });
    }

    test('draft-arman creates a draft for Арман on first use', () async {
      final _Subject subject = _Subject();

      final ContractEntity contract = await subject.load('draft-arman');

      expect(contract.id, 'draft-arman');
      expect(contract.number, 'EB-1054');
      expect(contract.status, ContractStatus.draft);
      expect(contract.guest.fullName, 'Арман Темирбек');
      expect(contract.stay.bookingId, 'booking-1039');
      expect(contract.history.single.kind, ContractHistoryKind.created);
      expect(contract.history.single.at, contractsTestNow);
    });

    test(
      'a created draft is reused and the next draft gets a new number',
      () async {
        final _Subject subject = _Subject();
        await subject.load('draft-arman');

        expect((await subject.load('draft-arman')).number, 'EB-1054');
        expect((await subject.load('draft-aizhan')).number, 'EB-1055');
      },
    );

    test(
      'receivedAt follows the clock while the seed keeps its dates',
      () async {
        final _Subject subject = _Subject();
        final ContractEntity first = await subject.load('eb-1052');

        subject.now = contractsTestNow.add(const Duration(minutes: 30));
        final ContractEntity second = await subject.load('eb-1052');

        expect(second.receivedAt, subject.now);
        expect(second.history, first.history);
        expect(second.remindAt, first.remindAt);
      },
    );
  });

  group('ContractsMockLocalImpl.updateGuest', () {
    test('saves the guest of a draft and keeps the phone', () async {
      final _Subject subject = _Subject();

      final ContractEntity updated = _right(
        await subject.update(
          'samal-daniyar',
          firstName: 'Даниияр',
          iin: '960312300215',
        ),
      );

      const ContractGuestEntity expected = ContractGuestEntity(
        firstName: 'Даниияр',
        lastName: 'Муратов',
        patronymic: 'Ерланович',
        iin: '960312300215',
        idNumber: '048216721',
        phone: '+77003184521',
      );
      expect(updated.guest, expected);
      expect(updated.status, ContractStatus.draft);
      expect((await subject.load('samal-daniyar')).guest, expected);
    });

    test('an empty patronymic is stored as null', () async {
      final _Subject subject = _Subject();

      final ContractEntity updated = _right(
        await subject.update('samal-daniyar', patronymic: ''),
      );

      expect(updated.guest.patronymic, isNull);
      expect((await subject.load('samal-daniyar')).guest.patronymic, isNull);
    });

    test(
      'changing the data of a sent contract puts it back to draft',
      () async {
        final _Subject subject = _Subject();

        final ContractEntity updated = _right(
          await subject.update('eb-1052', lastName: 'Муратовв'),
        );

        expect(updated.status, ContractStatus.draft);
        expect(updated.signingUrl, isNull);
        expect(updated.remindAt, isNull);
        final ContractEntity reloaded = await subject.load('eb-1052');
        expect(reloaded.status, ContractStatus.draft);
        expect(reloaded.signingUrl, isNull);
      },
    );

    test('saving unchanged data keeps a sent contract and its link', () async {
      final _Subject subject = _Subject();

      final ContractEntity updated = _right(await subject.update('eb-1052'));

      expect(updated.status, ContractStatus.opened);
      expect(updated.signingUrl, 'https://easybooking.kz/sign/eb-1052');
      expect(updated.remindAt, isNotNull);
    });

    test('a signed contract is alreadySigned and stays unchanged', () async {
      final _Subject subject = _Subject();
      final ContractEntity before = await subject.load('eb-1048');

      final Failure failure = _left(
        await subject.update('eb-1048', firstName: 'Другое'),
      );

      expect(
        failure,
        const ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );
      expect((await subject.load('eb-1048')).guest, before.guest);
    });

    test('an unknown contract is a 404', () async {
      expect(_left(await _Subject().update('missing')), _isNotFound);
    });
  });

  group('ContractsMockLocalImpl.sendContract', () {
    test('sends a draft: status, recipient, history, link, reminder', () async {
      final _Subject subject = _Subject();
      final ContractEntity before = await subject.load('samal-daniyar');

      final ContractEntity sent = _right(await subject.send('samal-daniyar'));

      const ContractRecipientEntity recipient = ContractRecipientEntity(
        channel: ContractDeliveryChannel.whatsApp,
        address: '+77011234567',
      );
      expect(sent.status, ContractStatus.sent);
      expect(sent.recipient, recipient);
      expect(sent.history, <ContractHistoryEntryEntity>[
        ...before.history,
        ContractHistoryEntryEntity(
          kind: ContractHistoryKind.sent,
          at: contractsTestNow,
          recipient: recipient,
        ),
      ]);
      expect(sent.signingUrl, 'https://easybooking.kz/sign/samal-daniyar-1');
      expect(sent.remindAt, DateTime(2026, 10, 22, 11, 41));
      expect(sent.receivedAt, contractsTestNow);
      expect(
        () => sent.history.add(sent.history.first),
        throwsUnsupportedError,
      );
    });

    test('the sent contract is kept for later loads', () async {
      final _Subject subject = _Subject();
      final ContractEntity sent = _right(await subject.send('samal-daniyar'));

      expect(await subject.load('samal-daniyar'), sent);
    });

    test('each send gets a new link and a new history entry', () async {
      final _Subject subject = _Subject();
      await subject.send('samal-daniyar');
      subject.now = contractsTestNow.add(const Duration(minutes: 10));

      final ContractEntity resent = _right(
        await subject.send(
          'samal-daniyar',
          channel: ContractDeliveryChannel.email,
          address: 'guest@mail.kz',
        ),
      );

      expect(resent.signingUrl, 'https://easybooking.kz/sign/samal-daniyar-2');
      expect(
        resent.history.where(
          (ContractHistoryEntryEntity e) => e.kind == ContractHistoryKind.sent,
        ),
        hasLength(2),
      );
      expect(resent.remindAt, DateTime(2026, 10, 22, 11, 51));
      expect(resent.recipient.channel, ContractDeliveryChannel.email);
    });

    test('editing after a send revokes the new link', () async {
      final _Subject subject = _Subject();
      await subject.send('samal-daniyar');

      final ContractEntity updated = _right(
        await subject.update('samal-daniyar', idNumber: '048216722'),
      );

      expect(updated.status, ContractStatus.draft);
      expect(updated.signingUrl, isNull);
      expect(updated.remindAt, isNull);
    });

    test('a signed contract is alreadySigned and stays unchanged', () async {
      final _Subject subject = _Subject();
      final ContractEntity before = await subject.load('eb-1015');

      expect(
        _left(await subject.send('eb-1015')),
        const ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );
      expect(
        (await subject.load('eb-1015')).history,
        before.history,
      );
    });

    test('an unknown contract is a 404', () async {
      expect(_left(await _Subject().send('missing')), _isNotFound);
    });
  });
}
