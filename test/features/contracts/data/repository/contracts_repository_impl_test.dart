import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/data/repository/contracts_repository_impl.dart';
import 'package:easy_booking/features/contracts/data/sources/local/contracts_mock_local.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';

import '../../../../helpers/fake_contracts_repository.dart';

const Failure _failure = StorageFailure(message: 'disk');

const UpdateContractGuestParamsEntity _guestParams =
    UpdateContractGuestParamsEntity(
      contractId: 'c1',
      firstName: 'Данияр',
      lastName: 'Муратов',
      patronymic: '',
      iin: '960312300214',
      idNumber: '048216721',
    );

const SendContractParamsEntity _sendParams = SendContractParamsEntity(
  contractId: 'c1',
  channel: ContractDeliveryChannel.sms,
  address: '+77003184521',
);

final class _FakeContractsMockLocal implements ContractsMockLocal {
  Either<Failure, ContractEntity> result = Right<Failure, ContractEntity>(
    testContract(),
  );
  Object? error;
  final List<Object> calls = <Object>[];

  Future<Either<Failure, ContractEntity>> _answer(Object call) async {
    calls.add(call);
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<Either<Failure, ContractEntity>> loadContract(String id) {
    return _answer(id);
  }

  @override
  Future<Either<Failure, ContractEntity>> updateGuest(
    UpdateContractGuestParamsEntity params,
  ) {
    return _answer(params);
  }

  @override
  Future<Either<Failure, ContractEntity>> sendContract(
    SendContractParamsEntity params,
  ) {
    return _answer(params);
  }
}

void main() {
  group('ContractsRepositoryImpl', () {
    late _FakeContractsMockLocal local;
    late ContractsRepositoryImpl repository;

    setUp(() {
      local = _FakeContractsMockLocal();
      repository = ContractsRepositoryImpl(local: local);
    });

    test('getContract forwards the id and returns the contract', () async {
      expect(
        await repository.getContract('c1'),
        Right<Failure, ContractEntity>(testContract()),
      );
      expect(local.calls, <Object>['c1']);
    });

    test('updateGuest forwards the params and returns the contract', () async {
      local.result = Right<Failure, ContractEntity>(testSentContract());

      expect(
        await repository.updateGuest(_guestParams),
        Right<Failure, ContractEntity>(testSentContract()),
      );
      expect(local.calls, <Object>[_guestParams]);
    });

    test('sendContract forwards the params and returns the contract', () async {
      local.result = Right<Failure, ContractEntity>(testSentContract());

      expect(
        await repository.sendContract(_sendParams),
        Right<Failure, ContractEntity>(testSentContract()),
      );
      expect(local.calls, <Object>[_sendParams]);
    });

    test('a source failure passes through every method unchanged', () async {
      local.result = const Left<Failure, ContractEntity>(_failure);

      expect(
        await repository.getContract('c1'),
        const Left<Failure, ContractEntity>(_failure),
      );
      expect(
        await repository.updateGuest(_guestParams),
        const Left<Failure, ContractEntity>(_failure),
      );
      expect(
        await repository.sendContract(_sendParams),
        const Left<Failure, ContractEntity>(_failure),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getContract('c1'), throwsStateError);
      await expectLater(repository.updateGuest(_guestParams), throwsStateError);
      await expectLater(repository.sendContract(_sendParams), throwsStateError);
    });

    test('works over the real mock source end to end', () async {
      final ContractsRepositoryImpl real = ContractsRepositoryImpl(
        local: ContractsMockLocalImpl(now: () => contractsTestNow),
      );

      final Either<Failure, ContractEntity> sent = await real.sendContract(
        const SendContractParamsEntity(
          contractId: 'samal-daniyar',
          channel: ContractDeliveryChannel.sms,
          address: '+77003184521',
        ),
      );
      final Either<Failure, ContractEntity> loaded = await real.getContract(
        'samal-daniyar',
      );

      expect(loaded, sent);
      expect(
        loaded.fold((_) => null, (ContractEntity c) => c.status),
        ContractStatus.sent,
      );
    });
  });
}
