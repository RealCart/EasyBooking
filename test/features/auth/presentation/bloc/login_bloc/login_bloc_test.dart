import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/send_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

const LoginSubmitted _submitted = LoginSubmitted(
  SendCodeParamsEntity(phone: '+7 (700) 123-45-67'),
);
const OtpChallengeEntity _challenge = OtpChallengeEntity(
  phone: '+77001234567',
  resendAfter: Duration(seconds: 30),
);
const Failure _tooManyRequests = ServerFailure(
  statusCode: 429,
  code: AuthErrorCodes.tooManyRequests,
);

void main() {
  late FakeAuthRepository repository;
  late LoginBloc bloc;
  late List<LoginState> states;

  setUp(() {
    repository = FakeAuthRepository();
    bloc = LoginBloc(sendCode: SendCodeUsecase(repository));
    states = <LoginState>[];
    final StreamSubscription<LoginState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(() async {
      await subscription.cancel();
      await bloc.close();
    });
  });

  test('starts idle', () {
    expect(bloc.state, const LoginState());
  });

  group('LoginSubmitted', () {
    test('sends the normalized phone of the params', () async {
      bloc.add(_submitted);
      await pumpEventQueue();

      expect(repository.sentPhones, <String>['+77001234567']);
    });

    test('emits loading, then success with the challenge', () async {
      bloc.add(_submitted);
      await pumpEventQueue();

      expect(states, <LoginState>[
        const LoginState(status: RequestStatus.loading),
        const LoginState(status: RequestStatus.success, challenge: _challenge),
      ]);
    });

    test('emits loading, then failure with the failure', () async {
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        _tooManyRequests,
      );

      bloc.add(_submitted);
      await pumpEventQueue();

      expect(states, <LoginState>[
        const LoginState(status: RequestStatus.loading),
        const LoginState(
          status: RequestStatus.failure,
          failure: _tooManyRequests,
        ),
      ]);
    });

    test('an invalid number fails with invalid_phone locally', () async {
      bloc.add(const LoginSubmitted(SendCodeParamsEntity(phone: '700')));
      await pumpEventQueue();

      expect(
        bloc.state.failure,
        const ValidationFailure(code: AuthErrorCodes.invalidPhone),
      );
      expect(repository.sentPhones, isEmpty);
    });

    test('a retry after failure clears the old failure', () async {
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        _tooManyRequests,
      );
      bloc.add(_submitted);
      await pumpEventQueue();
      repository.sendCodeResult = null;
      states.clear();

      bloc.add(_submitted);
      await pumpEventQueue();

      expect(states, <LoginState>[
        const LoginState(status: RequestStatus.loading),
        const LoginState(status: RequestStatus.success, challenge: _challenge),
      ]);
    });

    test('a second submit while loading is dropped', () async {
      repository.holdSendCode = true;

      bloc
        ..add(_submitted)
        ..add(_submitted);
      await pumpEventQueue();
      bloc.add(_submitted);
      await pumpEventQueue();

      expect(repository.sentPhones, hasLength(1));

      repository.heldSendCodes.single.complete(
        const Right<Failure, OtpChallengeEntity>(_challenge),
      );
      await pumpEventQueue();

      expect(states.map((LoginState state) => state.status), <RequestStatus>[
        RequestStatus.loading,
        RequestStatus.success,
      ]);
    });

    test(
      'closing while sending emits nothing more and throws nothing',
      () async {
        repository.holdSendCode = true;
        bloc.add(_submitted);
        await pumpEventQueue();

        await bloc.close();
        repository.heldSendCodes.single.complete(
          const Right<Failure, OtpChallengeEntity>(_challenge),
        );
        await pumpEventQueue();

        expect(states, <LoginState>[
          const LoginState(status: RequestStatus.loading),
        ]);
      },
    );
  });

  group('LoginState.copyWith', () {
    test('reset flags win over supplied values', () {
      const LoginState state = LoginState(
        failure: _tooManyRequests,
        challenge: _challenge,
      );

      final LoginState next = state.copyWith(
        failure: _tooManyRequests,
        resetFailure: true,
        challenge: _challenge,
        resetChallenge: true,
      );

      expect(next.failure, isNull);
      expect(next.challenge, isNull);
    });

    test('keeps omitted fields', () {
      const LoginState state = LoginState(
        status: RequestStatus.failure,
        failure: _tooManyRequests,
      );

      expect(state.copyWith(), state);
    });
  });
}
