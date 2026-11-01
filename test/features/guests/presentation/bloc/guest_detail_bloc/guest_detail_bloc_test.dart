import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';
import 'package:easy_booking/features/guests/presentation/bloc/guest_detail_bloc/guest_detail_bloc.dart';

import '../../../../../helpers/fake_guests_repository.dart';

const Failure _failure = ConnectionFailure();
const Failure _notFound = ServerFailure(statusCode: 404);

/// A [GuestDetailBloc] over a [FakeGuestsRepository] that records its
/// states.
final class _Subject {
  _Subject() {
    bloc = GuestDetailBloc(
      getGuest: GetGuestUsecase(repository),
      createContract: CreateGuestContractUsecase(repository),
    );
    final StreamSubscription<GuestDetailState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeGuestsRepository repository = FakeGuestsRepository();
  late final GuestDetailBloc bloc;
  final List<GuestDetailState> states = <GuestDetailState>[];

  Future<void> add(GuestDetailEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> loaded() async {
    await add(const GuestDetailRequested('g1'));
    states.clear();
  }
}

GuestDetailState _loaded({
  RequestStatus createContractStatus = RequestStatus.initial,
  String? createdContractId,
  Failure? createContractFailure,
}) {
  return GuestDetailState(
    guestId: 'g1',
    loadStatus: RequestStatus.success,
    guest: testGuest(),
    createContractStatus: createContractStatus,
    createdContractId: createdContractId,
    createContractFailure: createContractFailure,
  );
}

void main() {
  group('GuestDetailBloc load', () {
    test('starts empty and idle', () {
      final _Subject subject = _Subject();

      expect(subject.bloc.state, const GuestDetailState());
    });

    test('a load emits loading, then the guest', () async {
      final _Subject subject = _Subject();

      await subject.add(const GuestDetailRequested('g1'));

      expect(subject.repository.guestIds, <String>['g1']);
      expect(subject.states, <GuestDetailState>[
        const GuestDetailState(
          guestId: 'g1',
          loadStatus: RequestStatus.loading,
        ),
        _loaded(),
      ]);
    });

    test('a failed load keeps the requested id for a retry', () async {
      final _Subject subject = _Subject();
      subject.repository.guestResult = const Left<Failure, GuestEntity>(
        _notFound,
      );

      await subject.add(const GuestDetailRequested('missing'));

      expect(subject.states, <GuestDetailState>[
        const GuestDetailState(
          guestId: 'missing',
          loadStatus: RequestStatus.loading,
        ),
        const GuestDetailState(
          guestId: 'missing',
          loadStatus: RequestStatus.failure,
          loadFailure: _notFound,
        ),
      ]);
    });

    test('a retry clears the failure while loading', () async {
      final _Subject subject = _Subject();
      subject.repository.guestResult = const Left<Failure, GuestEntity>(
        _failure,
      );
      await subject.add(const GuestDetailRequested('g1'));
      subject.states.clear();
      subject.repository.guestResult = Right<Failure, GuestEntity>(
        testGuest(),
      );

      await subject.add(const GuestDetailRequested('g1'));

      expect(subject.states, <GuestDetailState>[
        const GuestDetailState(
          guestId: 'g1',
          loadStatus: RequestStatus.loading,
        ),
        _loaded(),
      ]);
    });

    test(
      'a reload keeps the shown guest while loading and after failing',
      () async {
        final _Subject subject = _Subject();
        await subject.loaded();
        subject.repository.guestResult = const Left<Failure, GuestEntity>(
          _failure,
        );

        await subject.add(const GuestDetailRequested('g1'));

        expect(subject.states, <GuestDetailState>[
          _loaded().copyWith(loadStatus: RequestStatus.loading),
          _loaded().copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: _failure,
          ),
        ]);
      },
    );

    test('an older load finishing last does not replace a newer one', () async {
      final _Subject subject = _Subject();
      subject.repository.holdGuest = true;

      await subject.add(const GuestDetailRequested('a'));
      await subject.add(const GuestDetailRequested('b'));
      subject.repository.heldGuest[1].complete(
        Right<Failure, GuestEntity>(testGuest(id: 'b')),
      );
      await pumpEventQueue();
      subject.repository.heldGuest[0].complete(
        Right<Failure, GuestEntity>(testGuest(id: 'a')),
      );
      await pumpEventQueue();

      expect(subject.repository.guestIds, <String>['a', 'b']);
      expect(subject.bloc.state.guestId, 'b');
      expect(subject.bloc.state.guest, testGuest(id: 'b'));
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test(
      'closing during an awaited load emits nothing and throws nothing',
      () async {
        final _Subject subject = _Subject();
        subject.repository.holdGuest = true;
        await subject.add(const GuestDetailRequested('g1'));

        await subject.bloc.close();
        subject.repository.heldGuest.single.complete(
          Right<Failure, GuestEntity>(testGuest()),
        );
        await pumpEventQueue();

        expect(subject.states, <GuestDetailState>[
          const GuestDetailState(
            guestId: 'g1',
            loadStatus: RequestStatus.loading,
          ),
        ]);
      },
    );
  });

  group('GuestDetailBloc contract creation', () {
    test('is ignored before the guest has loaded', () async {
      final _Subject subject = _Subject();

      await subject.add(const GuestContractCreationRequested());

      expect(subject.repository.createContractIds, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('is ignored after a failed first load', () async {
      final _Subject subject = _Subject();
      subject.repository.guestResult = const Left<Failure, GuestEntity>(
        _notFound,
      );
      await subject.add(const GuestDetailRequested('missing'));
      subject.states.clear();

      await subject.add(const GuestContractCreationRequested());

      expect(subject.repository.createContractIds, isEmpty);
      expect(subject.states, isEmpty);
    });

    test('emits loading, then the created contract id', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const GuestContractCreationRequested());

      expect(subject.repository.createContractIds, <String>['g1']);
      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
        _loaded(
          createContractStatus: RequestStatus.success,
          createdContractId: 'draft-g1',
        ),
      ]);
    });

    test('a failure is reported and the guest stays loaded', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.createContractResult = const Left<Failure, String>(
        _failure,
      );

      await subject.add(const GuestContractCreationRequested());

      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
        _loaded(
          createContractStatus: RequestStatus.failure,
          createContractFailure: _failure,
        ),
      ]);
    });

    test('a new creation clears the previous contract id', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      await subject.add(const GuestContractCreationRequested());
      subject.states.clear();
      subject.repository.createContractResult = const Left<Failure, String>(
        _failure,
      );

      await subject.add(const GuestContractCreationRequested());

      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
        _loaded(
          createContractStatus: RequestStatus.failure,
          createContractFailure: _failure,
        ),
      ]);
    });

    test('a new creation clears the previous failure', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.createContractResult = const Left<Failure, String>(
        _failure,
      );
      await subject.add(const GuestContractCreationRequested());
      subject.states.clear();
      subject.repository.createContractResult = const Right<Failure, String>(
        'draft-g1',
      );

      await subject.add(const GuestContractCreationRequested());

      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
        _loaded(
          createContractStatus: RequestStatus.success,
          createdContractId: 'draft-g1',
        ),
      ]);
    });

    test('a second tap while creating is dropped', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.holdCreateContract = true;

      await subject.add(const GuestContractCreationRequested());
      await subject.add(const GuestContractCreationRequested());
      expect(subject.repository.createContractIds, <String>['g1']);

      subject.repository.heldCreateContract.single.complete(
        const Right<Failure, String>('draft-g1'),
      );
      await pumpEventQueue();

      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
        _loaded(
          createContractStatus: RequestStatus.success,
          createdContractId: 'draft-g1',
        ),
      ]);
    });

    test('a tap after the creation finished starts another one', () async {
      final _Subject subject = _Subject();
      await subject.loaded();

      await subject.add(const GuestContractCreationRequested());
      await subject.add(const GuestContractCreationRequested());

      expect(subject.repository.createContractIds, <String>['g1', 'g1']);
    });

    test('closing during an awaited creation emits nothing more', () async {
      final _Subject subject = _Subject();
      await subject.loaded();
      subject.repository.holdCreateContract = true;
      await subject.add(const GuestContractCreationRequested());

      await subject.bloc.close();
      subject.repository.heldCreateContract.single.complete(
        const Right<Failure, String>('draft-g1'),
      );
      await pumpEventQueue();

      expect(subject.states, <GuestDetailState>[
        _loaded(createContractStatus: RequestStatus.loading),
      ]);
    });
  });

  group('GuestDetailState.copyWith', () {
    test('a reset flag wins over a supplied value', () {
      final GuestDetailState state = _loaded(
        createdContractId: 'draft-g1',
        createContractFailure: _failure,
      ).copyWith(loadFailure: _failure);

      final GuestDetailState reset = state.copyWith(
        loadFailure: _notFound,
        resetLoadFailure: true,
        createdContractId: 'other',
        resetCreatedContractId: true,
        createContractFailure: _notFound,
        resetCreateContractFailure: true,
      );

      expect(reset.loadFailure, isNull);
      expect(reset.createdContractId, isNull);
      expect(reset.createContractFailure, isNull);
      expect(reset.guest, testGuest());
    });
  });
}
