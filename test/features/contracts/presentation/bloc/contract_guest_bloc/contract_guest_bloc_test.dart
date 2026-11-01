import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_guest_bloc/contract_guest_bloc.dart';

import '../../../../../helpers/fake_contracts_repository.dart';

const UpdateContractGuestParamsEntity _params = UpdateContractGuestParamsEntity(
  contractId: 'c1',
  firstName: 'Данияр',
  lastName: 'Муратов',
  patronymic: 'Ерланович',
  iin: '960312300214',
  idNumber: '048216721',
);

final class _Subject {
  _Subject() {
    bloc = ContractGuestBloc(
      getContract: GetContractUsecase(repository),
      updateGuest: UpdateContractGuestUsecase(repository),
    );
    final StreamSubscription<ContractGuestState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeContractsRepository repository = FakeContractsRepository();
  late final ContractGuestBloc bloc;
  final List<ContractGuestState> states = <ContractGuestState>[];

  Future<void> add(ContractGuestEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  /// Loads [testContract] and forgets the states of the load.
  Future<void> loaded() async {
    await add(const ContractGuestRequested('c1'));
    states.clear();
  }
}

void main() {
  group('ContractGuestBloc', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const ContractGuestState());
    });

    test('a load emits loading, then the contract', () async {
      final _Subject subject = _Subject();

      await subject.add(const ContractGuestRequested('c1'));

      expect(subject.repository.getCalls, <String>['c1']);
      expect(subject.states, <ContractGuestState>[
        const ContractGuestState(
          contractId: 'c1',
          loadStatus: RequestStatus.loading,
        ),
        ContractGuestState(
          contractId: 'c1',
          loadStatus: RequestStatus.success,
          contract: testContract(),
        ),
      ]);
    });

    test('a failed load emits loading, then the failure', () async {
      final _Subject subject = _Subject();
      subject.repository.getResult = const Left<Failure, ContractEntity>(
        ServerFailure(statusCode: 404),
      );

      await subject.add(const ContractGuestRequested('missing'));

      expect(subject.states, <ContractGuestState>[
        const ContractGuestState(
          contractId: 'missing',
          loadStatus: RequestStatus.loading,
        ),
        const ContractGuestState(
          contractId: 'missing',
          loadStatus: RequestStatus.failure,
          loadFailure: ServerFailure(statusCode: 404),
        ),
      ]);
    });

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      subject.repository.getResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );
      await subject.add(const ContractGuestRequested('c1'));
      subject.states.clear();
      subject.repository.getResult = Right<Failure, ContractEntity>(
        testContract(),
      );

      await subject.add(const ContractGuestRequested('c1'));

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.states.first.loadStatus, RequestStatus.loading);
      expect(subject.bloc.state.contract, testContract());
    });

    test('a failed reload keeps the shown contract', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.getResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );

      await subject.add(const ContractGuestRequested('c1'));

      expect(subject.states, <ContractGuestState>[
        ContractGuestState(
          contractId: 'c1',
          loadStatus: RequestStatus.loading,
          contract: testContract(),
        ),
        ContractGuestState(
          contractId: 'c1',
          loadStatus: RequestStatus.failure,
          contract: testContract(),
          loadFailure: const ConnectionFailure(),
        ),
      ]);
    });

    test(
      'loads are restartable: an older answer never replaces a newer one',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdGet = true;
        await subject.add(const ContractGuestRequested('a'));
        await subject.add(const ContractGuestRequested('b'));

        subject.repository.heldGets[1].complete(
          Right<Failure, ContractEntity>(testContract(id: 'b')),
        );
        await pumpEventQueue();
        subject.repository.heldGets[0].complete(
          Right<Failure, ContractEntity>(testContract(id: 'a')),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.contractId, 'b');
        expect(subject.bloc.state.contract!.id, 'b');
        expect(
          subject.states.where(
            (ContractGuestState s) => s.contract?.id == 'a',
          ),
          isEmpty,
        );
      },
    );

    test(
      'a submit emits loading, then success with the saved contract',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.updateResult = Right<Failure, ContractEntity>(
          testSentContract(),
        );

        await subject.add(const ContractGuestSubmitted(_params));

        expect(
          subject.repository.updateCalls,
          <UpdateContractGuestParamsEntity>[
            _params,
          ],
        );
        expect(subject.states, <ContractGuestState>[
          ContractGuestState(
            contractId: 'c1',
            loadStatus: RequestStatus.success,
            contract: testContract(),
            submitStatus: RequestStatus.loading,
          ),
          ContractGuestState(
            contractId: 'c1',
            loadStatus: RequestStatus.success,
            contract: testSentContract(),
            submitStatus: RequestStatus.success,
          ),
        ]);
      },
    );

    test('invalid data shows field errors and saves nothing', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(
        const ContractGuestSubmitted(
          UpdateContractGuestParamsEntity(
            contractId: 'c1',
            firstName: ' ',
            lastName: 'Муратов',
            patronymic: '',
            iin: '123',
            idNumber: '048216721',
          ),
        ),
      );

      expect(subject.repository.updateCalls, isEmpty);
      final ContractGuestState state = subject.bloc.state;
      expect(state.submitStatus, RequestStatus.failure);
      expect(state.fieldErrors, <String, String>{
        ContractGuestFields.firstName: ContractErrorCodes.required,
        ContractGuestFields.iin: ContractErrorCodes.invalidIin,
      });
      expect(state.submitFailure, isNull);
      expect(() => state.fieldErrors['x'] = 'y', throwsUnsupportedError);
    });

    test('a field error for a hidden field is also a submit failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      const ValidationFailure failure = ValidationFailure(
        fieldErrors: <String, String>{'phone': 'invalid'},
      );
      subject.repository.updateResult = const Left<Failure, ContractEntity>(
        failure,
      );

      await subject.add(const ContractGuestSubmitted(_params));

      expect(subject.bloc.state.fieldErrors, <String, String>{
        'phone': 'invalid',
      });
      expect(subject.bloc.state.submitFailure, failure);
    });

    test(
      'a signed contract is a submit failure without field errors',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.updateResult = const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.alreadySigned),
        );

        await subject.add(const ContractGuestSubmitted(_params));

        expect(subject.bloc.state.submitStatus, RequestStatus.failure);
        expect(
          subject.bloc.state.submitFailure,
          const ValidationFailure(code: ContractErrorCodes.alreadySigned),
        );
        expect(subject.bloc.state.fieldErrors, isEmpty);
        expect(subject.bloc.state.contract, testContract());
      },
    );

    test('a new submit clears the previous errors while loading', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.updateResult = const Left<Failure, ContractEntity>(
        ValidationFailure(
          code: ContractErrorCodes.alreadySigned,
          fieldErrors: <String, String>{'phone': 'x'},
        ),
      );
      await subject.add(const ContractGuestSubmitted(_params));
      subject.states.clear();
      subject.repository.updateResult = Right<Failure, ContractEntity>(
        testContract(),
      );

      await subject.add(const ContractGuestSubmitted(_params));

      expect(subject.states.first.submitStatus, RequestStatus.loading);
      expect(subject.states.first.submitFailure, isNull);
      expect(subject.states.first.fieldErrors, isEmpty);
    });

    test(
      'editing a field clears only its error and resets the status',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.updateResult = const Left<Failure, ContractEntity>(
          ValidationFailure(
            fieldErrors: <String, String>{
              ContractGuestFields.iin: ContractErrorCodes.invalidIin,
              ContractGuestFields.idNumber: ContractErrorCodes.invalidIdNumber,
            },
          ),
        );
        await subject.add(const ContractGuestSubmitted(_params));

        await subject.add(
          const ContractGuestFieldEdited(ContractGuestFields.iin),
        );

        final ContractGuestState state = subject.bloc.state;
        expect(state.fieldErrors, <String, String>{
          ContractGuestFields.idNumber: ContractErrorCodes.invalidIdNumber,
        });
        expect(state.submitStatus, RequestStatus.initial);
        expect(state.submitFailure, isNull);
        expect(() => state.fieldErrors['x'] = 'y', throwsUnsupportedError);
      },
    );

    test('editing after a general failure clears the failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.updateResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );
      await subject.add(const ContractGuestSubmitted(_params));

      await subject.add(
        const ContractGuestFieldEdited(ContractGuestFields.firstName),
      );

      expect(subject.bloc.state.submitFailure, isNull);
      expect(subject.bloc.state.submitStatus, RequestStatus.initial);
    });

    test('editing without errors emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(
        const ContractGuestFieldEdited(ContractGuestFields.firstName),
      );

      expect(subject.states, isEmpty);
    });

    test(
      'submits are droppable: a second one while saving is ignored',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.holdUpdate = true;

        await subject.add(const ContractGuestSubmitted(_params));
        await subject.add(const ContractGuestSubmitted(_params));

        expect(subject.repository.updateCalls, hasLength(1));
        subject.repository.heldUpdates.single.complete(
          Right<Failure, ContractEntity>(testContract()),
        );
        await pumpEventQueue();
        expect(subject.bloc.state.submitStatus, RequestStatus.success);
      },
    );

    test('closing while a load is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      subject.repository.holdGet = true;
      await subject.add(const ContractGuestRequested('c1'));

      await subject.bloc.close();
      subject.repository.heldGets.single.complete(
        Right<Failure, ContractEntity>(testContract()),
      );
      await pumpEventQueue();

      expect(subject.states, <ContractGuestState>[
        const ContractGuestState(
          contractId: 'c1',
          loadStatus: RequestStatus.loading,
        ),
      ]);
    });

    test('closing while a submit is pending emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.holdUpdate = true;
      await subject.add(const ContractGuestSubmitted(_params));

      await subject.bloc.close();
      subject.repository.heldUpdates.single.complete(
        Right<Failure, ContractEntity>(testSentContract()),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(1));
      expect(subject.bloc.state.submitStatus, RequestStatus.loading);
    });
  });
}
