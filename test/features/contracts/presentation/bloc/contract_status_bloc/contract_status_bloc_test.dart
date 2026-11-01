import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_status_bloc/contract_status_bloc.dart';

import '../../../../../helpers/fake_contracts_repository.dart';

final class _Subject {
  _Subject() {
    bloc = ContractStatusBloc(
      getContract: GetContractUsecase(repository),
      sendContract: SendContractUsecase(repository),
    );
    final StreamSubscription<ContractStatusState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeContractsRepository repository = FakeContractsRepository();
  late final ContractStatusBloc bloc;
  final List<ContractStatusState> states = <ContractStatusState>[];

  Future<void> add(ContractStatusEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> loaded(ContractEntity contract) async {
    repository.getResult = Right<Failure, ContractEntity>(contract);
    await add(const ContractStatusRequested('c1'));
    states.clear();
  }
}

void main() {
  group('ContractStatusBloc', () {
    test('starts empty and cannot resend', () {
      final ContractStatusState state = _Subject().bloc.state;

      expect(state, const ContractStatusState());
      expect(state.canResend, isFalse);
    });

    test('a load emits loading, then the contract', () async {
      final _Subject subject = _Subject();
      subject.repository.getResult = Right<Failure, ContractEntity>(
        testSentContract(),
      );

      await subject.add(const ContractStatusRequested('c1'));

      expect(subject.states, <ContractStatusState>[
        const ContractStatusState(
          contractId: 'c1',
          loadStatus: RequestStatus.loading,
        ),
        ContractStatusState(
          contractId: 'c1',
          loadStatus: RequestStatus.success,
          contract: testSentContract(),
        ),
      ]);
      expect(subject.bloc.state.canResend, isTrue);
    });

    test(
      'a failed reload keeps the contract and reports the failure',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded(testSentContract());
        subject.repository.getResult = const Left<Failure, ContractEntity>(
          TimeoutFailure(),
        );

        await subject.add(const ContractStatusRequested('c1'));

        expect(subject.states, <ContractStatusState>[
          ContractStatusState(
            contractId: 'c1',
            loadStatus: RequestStatus.loading,
            contract: testSentContract(),
          ),
          ContractStatusState(
            contractId: 'c1',
            loadStatus: RequestStatus.failure,
            contract: testSentContract(),
            loadFailure: const TimeoutFailure(),
          ),
        ]);
      },
    );

    test(
      'loads are restartable: an older answer never replaces a newer one',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdGet = true;
        await subject.add(const ContractStatusRequested('a'));
        await subject.add(const ContractStatusRequested('b'));

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

    test(
      'a load that started before a resend keeps the sent contract',
      () async {
        final _Subject subject = _Subject();
        final ContractEntity resent = testSentContract().copyWith(
          signingUrl: 'https://easybooking.kz/sign/c1-2',
        );
        await subject.loaded(testSentContract());
        subject.repository.holdGet = true;
        subject.repository.sendResult = Right<Failure, ContractEntity>(resent);
        await subject.add(const ContractStatusRequested('c1'));

        await subject.add(const ContractResendRequested());
        subject.repository.heldGets.single.complete(
          Right<Failure, ContractEntity>(testSentContract()),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.contract, resent);
        expect(subject.bloc.state.loadStatus, RequestStatus.success);
        expect(subject.bloc.state.resendStatus, RequestStatus.success);
      },
    );

    test('a load that started before a failed resend applies', () async {
      final _Subject subject = _Subject();
      final ContractEntity reloaded = testSentContract().copyWith(
        signingUrl: 'https://easybooking.kz/sign/c1-3',
      );
      await subject.loaded(testSentContract());
      subject.repository.holdGet = true;
      subject.repository.sendResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );
      await subject.add(const ContractStatusRequested('c1'));

      await subject.add(const ContractResendRequested());
      subject.repository.heldGets.single.complete(
        Right<Failure, ContractEntity>(reloaded),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.contract, reloaded);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test(
      'a resend sends to the contract recipient and shows the result',
      () async {
        final _Subject subject = _Subject();
        final ContractEntity resent = testSentContract().copyWith(
          signingUrl: 'https://easybooking.kz/sign/c1-2',
        );
        await subject.loaded(testSentContract());
        subject.repository.sendResult = Right<Failure, ContractEntity>(resent);

        await subject.add(const ContractResendRequested());

        expect(subject.repository.sendCalls, <SendContractParamsEntity>[
          const SendContractParamsEntity(
            contractId: 'c1',
            channel: ContractDeliveryChannel.sms,
            address: '+77003184521',
          ),
        ]);
        expect(subject.states, <ContractStatusState>[
          ContractStatusState(
            contractId: 'c1',
            loadStatus: RequestStatus.success,
            contract: testSentContract(),
            resendStatus: RequestStatus.loading,
          ),
          ContractStatusState(
            contractId: 'c1',
            loadStatus: RequestStatus.success,
            contract: resent,
            resendStatus: RequestStatus.success,
          ),
        ]);
      },
    );

    test('canResend is false while a resend is running', () async {
      final _Subject subject = _Subject();
      await subject.loaded(testSentContract());
      subject.repository.holdSend = true;

      await subject.add(const ContractResendRequested());

      expect(subject.bloc.state.resendStatus, RequestStatus.loading);
      expect(subject.bloc.state.canResend, isFalse);
    });

    test(
      'a failed resend keeps the contract and reports the failure',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded(testSentContract());
        subject.repository.sendResult = const Left<Failure, ContractEntity>(
          ConnectionFailure(),
        );

        await subject.add(const ContractResendRequested());

        expect(subject.bloc.state.resendStatus, RequestStatus.failure);
        expect(subject.bloc.state.resendFailure, const ConnectionFailure());
        expect(subject.bloc.state.contract, testSentContract());
        expect(subject.bloc.state.canResend, isTrue);
      },
    );

    test('the next resend clears the previous failure while loading', () async {
      final _Subject subject = _Subject();
      await subject.loaded(testSentContract());
      subject.repository.sendResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );
      await subject.add(const ContractResendRequested());
      subject.states.clear();
      subject.repository.sendResult = Right<Failure, ContractEntity>(
        testSentContract(),
      );

      await subject.add(const ContractResendRequested());

      expect(subject.states.first.resendStatus, RequestStatus.loading);
      expect(subject.states.first.resendFailure, isNull);
      expect(subject.bloc.state.resendStatus, RequestStatus.success);
    });

    test('a resend before the contract loads does nothing', () async {
      final _Subject subject = _Subject();

      await subject.add(const ContractResendRequested());

      expect(subject.states, isEmpty);
      expect(subject.repository.sendCalls, isEmpty);
    });

    test('a signed contract cannot be resent', () async {
      final _Subject subject = _Subject();
      await subject.loaded(testSignedContract());

      expect(subject.bloc.state.canResend, isFalse);
      await subject.add(const ContractResendRequested());

      expect(subject.states, isEmpty);
      expect(subject.repository.sendCalls, isEmpty);
    });

    test(
      'resends are droppable: a second one while sending is ignored',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded(testSentContract());
        subject.repository.holdSend = true;

        await subject.add(const ContractResendRequested());
        await subject.add(const ContractResendRequested());

        expect(subject.repository.sendCalls, hasLength(1));
      },
    );

    test('closing while a resend is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.loaded(testSentContract());
      subject.repository.holdSend = true;
      await subject.add(const ContractResendRequested());

      await subject.bloc.close();
      subject.repository.heldSends.single.complete(
        Right<Failure, ContractEntity>(testSentContract()),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
      expect(subject.bloc.state.resendStatus, RequestStatus.loading);
    });

    test('closing while a load is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdGet = true;
      await subject.add(const ContractStatusRequested('c1'));

      await subject.bloc.close();
      subject.repository.heldGets.single.complete(
        Right<Failure, ContractEntity>(testSentContract()),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
    });
  });
}
