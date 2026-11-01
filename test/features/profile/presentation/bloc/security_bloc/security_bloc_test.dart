import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/security_bloc/security_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

final SecurityOverviewEntity _overview = testSecurityOverview();
final SecurityOverviewEntity _biometricOff = testSecurityOverview(
  isBiometricLoginEnabled: false,
);
final SecurityOverviewEntity _terminated = testSecurityOverview(
  hasOtherSession: false,
);

/// A [SecurityBloc] over a [FakeProfileRepository] that records its states.
final class _Subject {
  _Subject() {
    repository.biometricResult = Right<Failure, SecurityOverviewEntity>(
      _biometricOff,
    );
    bloc = SecurityBloc(
      getSecurityOverview: GetSecurityOverviewUsecase(repository),
      setBiometricLogin: SetBiometricLoginUsecase(repository),
      terminateOtherSessions: TerminateOtherSessionsUsecase(repository),
    );
    final StreamSubscription<SecurityState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final SecurityBloc bloc;
  final List<SecurityState> states = <SecurityState>[];

  Future<void> add(SecurityEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> load() async {
    await add(const SecurityRequested());
    states.clear();
  }
}

void main() {
  group('SecurityBloc load', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const SecurityState());
    });

    test('a load emits loading, then the overview', () async {
      final _Subject subject = _Subject();

      await subject.add(const SecurityRequested());

      expect(subject.states, <SecurityState>[
        const SecurityState(loadStatus: RequestStatus.loading),
        SecurityState(loadStatus: RequestStatus.success, overview: _overview),
      ]);
    });

    test('a failed refresh keeps the overview; a retry clears it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.securityResult =
          const Left<Failure, SecurityOverviewEntity>(_failure);

      await subject.add(const SecurityRequested());

      expect(subject.bloc.state.loadStatus, RequestStatus.failure);
      expect(subject.bloc.state.loadFailure, _failure);
      expect(subject.bloc.state.overview, _overview);

      subject.repository.securityResult =
          Right<Failure, SecurityOverviewEntity>(_overview);
      subject.states.clear();
      await subject.add(const SecurityRequested());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.loadStatus, RequestStatus.success);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSecurity = true;
      await subject.add(const SecurityRequested());
      await subject.add(const SecurityRequested());

      subject.repository.heldSecurity[1].complete(
        Right<Failure, SecurityOverviewEntity>(_overview),
      );
      await pumpEventQueue();
      subject.repository.heldSecurity[0].complete(
        Right<Failure, SecurityOverviewEntity>(_terminated),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.overview, _overview);
    });

    test(
      'a load that started before a write keeps the written overview',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.holdSecurity = true;
        await subject.add(const SecurityRequested());

        await subject.add(const SecurityOtherSessionsTerminateRequested());
        subject.repository.heldSecurity.single.complete(
          Right<Failure, SecurityOverviewEntity>(_overview),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.overview, _terminated);
        expect(subject.bloc.state.loadStatus, RequestStatus.success);
      },
    );

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdSecurity = true;
      await subject.add(const SecurityRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldSecurity.single.complete(
        Right<Failure, SecurityOverviewEntity>(_overview),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('SecurityBloc biometric login', () {
    test('a toggle emits saving, then the confirmed overview', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(const SecurityBiometricLoginToggled(isEnabled: false));

      expect(subject.states, <SecurityState>[
        SecurityState(
          loadStatus: RequestStatus.success,
          overview: _overview,
          biometricStatus: RequestStatus.loading,
        ),
        SecurityState(
          loadStatus: RequestStatus.success,
          overview: _biometricOff,
          biometricStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.repository.biometricValues, <bool>[false]);
    });

    test('a failed toggle keeps the saved value', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.biometricResult =
          const Left<Failure, SecurityOverviewEntity>(_failure);

      await subject.add(const SecurityBiometricLoginToggled(isEnabled: false));

      expect(subject.bloc.state.biometricStatus, RequestStatus.failure);
      expect(subject.bloc.state.biometricFailure, _failure);
      expect(subject.bloc.state.overview?.isBiometricLoginEnabled, isTrue);
    });

    test('a second toggle while saving is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdBiometric = true;

      await subject.add(const SecurityBiometricLoginToggled(isEnabled: false));
      await subject.add(const SecurityBiometricLoginToggled(isEnabled: true));
      subject.repository.heldBiometric.single.complete(
        Right<Failure, SecurityOverviewEntity>(_biometricOff),
      );
      await pumpEventQueue();

      expect(subject.repository.biometricValues, <bool>[false]);
    });

    test('a new toggle clears the earlier failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.biometricResult =
          const Left<Failure, SecurityOverviewEntity>(_failure);
      await subject.add(const SecurityBiometricLoginToggled(isEnabled: false));
      subject.repository.biometricResult =
          Right<Failure, SecurityOverviewEntity>(_biometricOff);
      subject.states.clear();

      await subject.add(const SecurityBiometricLoginToggled(isEnabled: false));

      expect(subject.states.first.biometricFailure, isNull);
    });
  });

  group('SecurityBloc terminate other sessions', () {
    test(
      'emits terminating, then the overview without other sessions',
      () async {
        final _Subject subject = _Subject();
        await subject.load();

        await subject.add(const SecurityOtherSessionsTerminateRequested());

        expect(subject.states, <SecurityState>[
          SecurityState(
            loadStatus: RequestStatus.success,
            overview: _overview,
            terminateStatus: RequestStatus.loading,
          ),
          SecurityState(
            loadStatus: RequestStatus.success,
            overview: _terminated,
            terminateStatus: RequestStatus.success,
          ),
        ]);
      },
    );

    test('a failure keeps the sessions and reports it', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.terminateResult =
          const Left<Failure, SecurityOverviewEntity>(_failure);

      await subject.add(const SecurityOtherSessionsTerminateRequested());

      expect(subject.bloc.state.terminateStatus, RequestStatus.failure);
      expect(subject.bloc.state.terminateFailure, _failure);
      expect(subject.bloc.state.overview, _overview);
    });

    test('a second request while terminating is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdTerminate = true;

      await subject.add(const SecurityOtherSessionsTerminateRequested());
      await subject.add(const SecurityOtherSessionsTerminateRequested());
      subject.repository.heldTerminate.single.complete(
        Right<Failure, SecurityOverviewEntity>(_terminated),
      );
      await pumpEventQueue();

      expect(subject.repository.terminateCount, 1);
    });

    test('completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdTerminate = true;
      await subject.add(const SecurityOtherSessionsTerminateRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldTerminate.single.complete(
        Right<Failure, SecurityOverviewEntity>(_terminated),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });
}
