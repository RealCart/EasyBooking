import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_send_bloc/contract_send_bloc.dart';

import '../../../../../helpers/fake_contracts_repository.dart';

const SendContractParamsEntity _params = SendContractParamsEntity(
  contractId: 'c1',
  channel: ContractDeliveryChannel.whatsApp,
  address: '701 123 45 67',
);

final class _Subject {
  _Subject() {
    bloc = ContractSendBloc(
      getContract: GetContractUsecase(repository),
      sendContract: SendContractUsecase(repository),
    );
    final StreamSubscription<ContractSendState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeContractsRepository repository = FakeContractsRepository();
  late final ContractSendBloc bloc;
  final List<ContractSendState> states = <ContractSendState>[];

  Future<void> add(ContractSendEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> loaded() async {
    await add(const ContractSendRequested('c1'));
    states.clear();
  }
}

void main() {
  group('ContractSendBloc', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const ContractSendState());
    });

    test('a load emits loading, then the contract', () async {
      final _Subject subject = _Subject();

      await subject.add(const ContractSendRequested('c1'));

      expect(subject.states, <ContractSendState>[
        const ContractSendState(
          contractId: 'c1',
          loadStatus: RequestStatus.loading,
        ),
        ContractSendState(
          contractId: 'c1',
          loadStatus: RequestStatus.success,
          contract: testContract(),
        ),
      ]);
    });

    test('a failed load emits loading, then the failure', () async {
      final _Subject subject = _Subject();
      subject.repository.getResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );

      await subject.add(const ContractSendRequested('c1'));

      expect(
        subject.states.last,
        const ContractSendState(
          contractId: 'c1',
          loadStatus: RequestStatus.failure,
          loadFailure: ConnectionFailure(),
        ),
      );
    });

    test('a failed reload keeps the shown contract', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.getResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );

      await subject.add(const ContractSendRequested('c1'));

      expect(subject.states.first.contract, testContract());
      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.contract, testContract());
      expect(subject.bloc.state.loadFailure, const ConnectionFailure());
    });

    test(
      'loads are restartable: an older answer never replaces a newer one',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdGet = true;
        await subject.add(const ContractSendRequested('a'));
        await subject.add(const ContractSendRequested('b'));

        subject.repository.heldGets[1].complete(
          Right<Failure, ContractEntity>(testContract(id: 'b')),
        );
        await pumpEventQueue();
        subject.repository.heldGets[0].complete(
          Right<Failure, ContractEntity>(testContract(id: 'a')),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.contract!.id, 'b');
      },
    );

    test('a send emits loading, then success with the sent contract', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const ContractSendSubmitted(_params));

      expect(subject.repository.sendCalls, <SendContractParamsEntity>[
        const SendContractParamsEntity(
          contractId: 'c1',
          channel: ContractDeliveryChannel.whatsApp,
          address: '+77011234567',
        ),
      ]);
      expect(subject.states, <ContractSendState>[
        ContractSendState(
          contractId: 'c1',
          loadStatus: RequestStatus.success,
          contract: testContract(),
          sendStatus: RequestStatus.loading,
        ),
        ContractSendState(
          contractId: 'c1',
          loadStatus: RequestStatus.success,
          contract: testSentContract(),
          sendStatus: RequestStatus.success,
        ),
      ]);
    });

    test('an invalid phone fails without sending', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(
        const ContractSendSubmitted(
          SendContractParamsEntity(
            contractId: 'c1',
            channel: ContractDeliveryChannel.sms,
            address: '700',
          ),
        ),
      );

      expect(subject.repository.sendCalls, isEmpty);
      expect(subject.bloc.state.sendStatus, RequestStatus.failure);
      expect(
        subject.bloc.state.sendFailure,
        const ValidationFailure(code: ContractErrorCodes.invalidPhone),
      );
      expect(subject.bloc.state.contract, testContract());
    });

    test('a repository failure is the send failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.sendResult = const Left<Failure, ContractEntity>(
        ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );

      await subject.add(const ContractSendSubmitted(_params));

      expect(
        subject.bloc.state.sendFailure,
        const ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );
    });

    test('a new send clears the previous failure while loading', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.sendResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );
      await subject.add(const ContractSendSubmitted(_params));
      subject.states.clear();
      subject.repository.sendResult = Right<Failure, ContractEntity>(
        testSentContract(),
      );

      await subject.add(const ContractSendSubmitted(_params));

      expect(subject.states.first.sendStatus, RequestStatus.loading);
      expect(subject.states.first.sendFailure, isNull);
      expect(subject.bloc.state.sendStatus, RequestStatus.success);
    });

    test(
      'sends are droppable: a second one while sending is ignored',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.holdSend = true;

        await subject.add(const ContractSendSubmitted(_params));
        await subject.add(const ContractSendSubmitted(_params));

        expect(subject.repository.sendCalls, hasLength(1));
      },
    );

    test('closing while a send is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.holdSend = true;
      await subject.add(const ContractSendSubmitted(_params));

      await subject.bloc.close();
      subject.repository.heldSends.single.complete(
        Right<Failure, ContractEntity>(testSentContract()),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
      expect(subject.bloc.state.sendStatus, RequestStatus.loading);
    });

    test('closing while a load is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdGet = true;
      await subject.add(const ContractSendRequested('c1'));

      await subject.bloc.close();
      subject.repository.heldGets.single.complete(
        Right<Failure, ContractEntity>(testContract()),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
    });
  });
}
