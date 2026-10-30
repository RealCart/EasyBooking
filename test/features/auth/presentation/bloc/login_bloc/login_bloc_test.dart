import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

const String _national = '7001234567';
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

  Future<void> typeValidPhone() async {
    bloc.add(const LoginPhoneChanged(_national));
    await pumpEventQueue();
    states.clear();
  }

  test('starts empty with submit disabled', () {
    expect(bloc.state, const LoginState());
    expect(bloc.state.canSubmit, isFalse);
  });

  group('LoginPhoneChanged', () {
    test('keeps only the national digits of a formatted number', () async {
      bloc.add(const LoginPhoneChanged('+7 (700) 123-45-67'));
      await pumpEventQueue();

      expect(states, <LoginState>[const LoginState(phone: _national)]);
      expect(bloc.state.canSubmit, isTrue);
    });

    test('an incomplete number cannot be submitted', () async {
      bloc.add(const LoginPhoneChanged('700 123'));
      await pumpEventQueue();

      expect(bloc.state.phone, '700123');
      expect(bloc.state.canSubmit, isFalse);
    });

    test('the same digits emit nothing', () async {
      await typeValidPhone();

      bloc.add(const LoginPhoneChanged('700 123 45 67'));
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test('resets status, failure and challenge', () async {
      await typeValidPhone();
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        _tooManyRequests,
      );
      bloc.add(const LoginSubmitted());
      await pumpEventQueue();
      expect(bloc.state.status, RequestStatus.failure);

      bloc.add(const LoginPhoneChanged('7001234568'));
      await pumpEventQueue();

      expect(bloc.state, const LoginState(phone: '7001234568'));
    });

    test('after success a change clears the challenge', () async {
      await typeValidPhone();
      bloc.add(const LoginSubmitted());
      await pumpEventQueue();
      expect(bloc.state.challenge, _challenge);

      bloc.add(const LoginPhoneChanged('700123456'));
      await pumpEventQueue();

      expect(bloc.state, const LoginState(phone: '700123456'));
    });
  });

  group('LoginSubmitted', () {
    test('emits loading, then success with the challenge', () async {
      await typeValidPhone();

      bloc.add(const LoginSubmitted());
      await pumpEventQueue();

      expect(states, <LoginState>[
        const LoginState(phone: _national, status: RequestStatus.loading),
        const LoginState(
          phone: _national,
          status: RequestStatus.success,
          challenge: _challenge,
        ),
      ]);
      expect(repository.sentPhones, <String>['+77001234567']);
    });

    test('emits loading, then failure with the failure', () async {
      await typeValidPhone();
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        _tooManyRequests,
      );

      bloc.add(const LoginSubmitted());
      await pumpEventQueue();

      expect(states, <LoginState>[
        const LoginState(phone: _national, status: RequestStatus.loading),
        const LoginState(
          phone: _national,
          status: RequestStatus.failure,
          failure: _tooManyRequests,
        ),
      ]);
    });

    test('an incomplete number fails with invalid_phone locally', () async {
      bloc.add(const LoginPhoneChanged('700'));
      await pumpEventQueue();

      bloc.add(const LoginSubmitted());
      await pumpEventQueue();

      expect(
        bloc.state.failure,
        const ValidationFailure(code: AuthErrorCodes.invalidPhone),
      );
      expect(repository.sentPhones, isEmpty);
    });

    test('a retry after failure clears the old failure', () async {
      await typeValidPhone();
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        _tooManyRequests,
      );
      bloc.add(const LoginSubmitted());
      await pumpEventQueue();
      repository.sendCodeResult = null;
      states.clear();

      bloc.add(const LoginSubmitted());
      await pumpEventQueue();

      expect(
        states.first,
        const LoginState(
          phone: _national,
          status: RequestStatus.loading,
        ),
      );
      expect(states.last.status, RequestStatus.success);
    });

    test('a second submit while loading is dropped', () async {
      await typeValidPhone();
      repository.holdSendCode = true;

      bloc
        ..add(const LoginSubmitted())
        ..add(const LoginSubmitted());
      await pumpEventQueue();
      bloc.add(const LoginSubmitted());
      await pumpEventQueue();

      expect(repository.sentPhones, hasLength(1));
      expect(bloc.state.canSubmit, isFalse);

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
      'a phone change while loading is ignored and the result applies',
      () async {
        await typeValidPhone();
        repository.holdSendCode = true;
        bloc.add(const LoginSubmitted());
        await pumpEventQueue();

        bloc.add(const LoginPhoneChanged('7009999999'));
        await pumpEventQueue();

        expect(bloc.state.phone, _national);
        expect(bloc.state.status, RequestStatus.loading);

        repository.heldSendCodes.single.complete(
          const Right<Failure, OtpChallengeEntity>(_challenge),
        );
        await pumpEventQueue();

        expect(states, <LoginState>[
          const LoginState(phone: _national, status: RequestStatus.loading),
          const LoginState(
            phone: _national,
            status: RequestStatus.success,
            challenge: _challenge,
          ),
        ]);
      },
    );

    test(
      'closing while sending emits nothing more and throws nothing',
      () async {
        await typeValidPhone();
        repository.holdSendCode = true;
        bloc.add(const LoginSubmitted());
        await pumpEventQueue();

        await bloc.close();
        repository.heldSendCodes.single.complete(
          const Right<Failure, OtpChallengeEntity>(_challenge),
        );
        await pumpEventQueue();

        expect(states, <LoginState>[
          const LoginState(phone: _national, status: RequestStatus.loading),
        ]);
        expect(bloc.state.status, RequestStatus.loading);
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
        phone: _national,
        status: RequestStatus.failure,
        failure: _tooManyRequests,
      );

      expect(state.copyWith(), state);
    });
  });
}
