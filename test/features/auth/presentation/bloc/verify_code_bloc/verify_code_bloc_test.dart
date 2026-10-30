import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

const String _phone = '+77001234567';
const Failure _invalidCode = ValidationFailure(
  code: AuthErrorCodes.invalidCode,
);
const Failure _tooManyRequests = ServerFailure(
  statusCode: 429,
  code: AuthErrorCodes.tooManyRequests,
);

/// A [VerifyCodeBloc] over a [FakeAuthRepository] that records its states.
///
/// Runs inside `testWidgets` so the countdown is driven by
/// `tester.pump(duration)`. [close] starts closing and pumps instead of
/// awaiting, which can hang in the fake-async zone.
final class _Subject {
  _Subject(this.tester) {
    bloc = VerifyCodeBloc(
      verifyCode: VerifyCodeUsecase(repository),
      sendCode: SendCodeUsecase(repository),
    );
    final StreamSubscription<VerifyCodeState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
  }

  final WidgetTester tester;
  final FakeAuthRepository repository = FakeAuthRepository();
  late final VerifyCodeBloc bloc;
  final List<VerifyCodeState> states = <VerifyCodeState>[];

  Future<void> add(VerifyCodeEvent event) async {
    bloc.add(event);
    await tester.pump();
  }

  Future<void> start(Duration resendAfter) async {
    await add(VerifyCodeStarted(phone: _phone, resendAfter: resendAfter));
    states.clear();
  }

  /// Starts closing and pumps. `close()` cancels the countdown
  /// synchronously; its future is not awaited because it does not complete
  /// inside the fake-async zone. [states] keeps recording afterwards so
  /// tests can check that nothing more is emitted.
  Future<void> close() async {
    unawaited(bloc.close());
    await tester.pump();
  }

  /// Starts with no countdown and fails the first verify, leaving the
  /// state with a cleared code and an `invalid_code` failure.
  Future<void> startWithVerifyFailure() async {
    await start(Duration.zero);
    repository.verifyCodeResult = const Left<Failure, void>(_invalidCode);
    await add(const VerifyCodeChanged('111111'));
    repository.verifyCodeResult = voidSuccess;
    states.clear();
  }
}

void main() {
  testWidgets('starts empty and allows a resend', (WidgetTester tester) async {
    final _Subject subject = _Subject(tester);

    expect(subject.bloc.state, const VerifyCodeState());
    expect(subject.bloc.state.canResend, isTrue);
    expect(subject.bloc.state.canSubmit, isFalse);

    await subject.close();
  });

  group('countdown', () {
    testWidgets('VerifyCodeStarted sets the phone and the delay', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);

      await subject.add(
        const VerifyCodeStarted(
          phone: _phone,
          resendAfter: Duration(seconds: 3),
        ),
      );

      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(
          phone: _phone,
          resendAvailableIn: Duration(seconds: 3),
        ),
      ]);
      expect(subject.bloc.state.canResend, isFalse);

      await subject.close();
    });

    testWidgets('ticks once per second down to zero, then stops', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(const Duration(seconds: 3));

      await tester.pump(const Duration(milliseconds: 999));
      expect(subject.states, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 10));

      expect(
        subject.states.map((VerifyCodeState s) => s.resendAvailableIn),
        <Duration>[
          const Duration(seconds: 2),
          const Duration(seconds: 1),
          Duration.zero,
        ],
      );
      expect(subject.bloc.state.canResend, isTrue);

      await subject.close();
    });

    testWidgets('a zero or negative delay starts no countdown', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);

      await subject.add(
        const VerifyCodeStarted(
          phone: _phone,
          resendAfter: Duration(seconds: -5),
        ),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(phone: _phone),
      ]);

      await subject.close();
    });

    testWidgets('closing with a running countdown stops the ticks', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(const Duration(seconds: 30));
      await tester.pump(const Duration(seconds: 1));

      await subject.close();
      await tester.pump(const Duration(seconds: 5));

      expect(
        subject.states.map((VerifyCodeState s) => s.resendAvailableIn),
        <Duration>[const Duration(seconds: 29)],
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('resend', () {
    testWidgets('is blocked while the countdown runs', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(const Duration(seconds: 30));

      await subject.add(const VerifyCodeResendRequested());

      expect(subject.states, isEmpty);
      expect(subject.repository.sentPhones, isEmpty);

      await subject.close();
    });

    testWidgets('after the countdown sends and restarts it', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      subject.states.clear();
      subject.repository.resendAfter = const Duration(seconds: 60);

      await subject.add(const VerifyCodeResendRequested());

      expect(subject.repository.sentPhones, <String>[_phone]);
      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(
          phone: _phone,
          resendStatus: RequestStatus.loading,
        ),
        const VerifyCodeState(
          phone: _phone,
          resendStatus: RequestStatus.success,
          resendAvailableIn: Duration(seconds: 60),
        ),
      ]);

      await tester.pump(const Duration(seconds: 1));
      expect(
        subject.bloc.state.resendAvailableIn,
        const Duration(seconds: 59),
      );

      await subject.close();
    });

    testWidgets('success clears the code and the verify failure', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.startWithVerifyFailure();
      await subject.add(const VerifyCodeChanged('12'));
      // Typing reset the failure; fail again so resend has one to clear.
      expect(subject.bloc.state.verifyFailure, isNull);
      subject.repository.verifyCodeResult = const Left<Failure, void>(
        _invalidCode,
      );
      await subject.add(const VerifyCodeChanged('123456'));
      expect(subject.bloc.state.verifyFailure, _invalidCode);
      await subject.add(const VerifyCodeChanged('12'));
      subject.states.clear();

      await subject.add(const VerifyCodeResendRequested());

      expect(
        subject.bloc.state,
        const VerifyCodeState(
          phone: _phone,
          resendStatus: RequestStatus.success,
          resendAvailableIn: Duration(seconds: 30),
        ),
      );

      await subject.close();
    });

    testWidgets('a resend success clears a verify failure state', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.startWithVerifyFailure();
      expect(subject.bloc.state.verifyStatus, RequestStatus.failure);

      await subject.add(const VerifyCodeResendRequested());

      expect(subject.bloc.state.verifyStatus, RequestStatus.initial);
      expect(subject.bloc.state.verifyFailure, isNull);
      expect(subject.bloc.state.code, isEmpty);

      await subject.close();
    });

    testWidgets('a failure is independent of the verify state', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.startWithVerifyFailure();
      subject.repository.sendCodeResult =
          const Left<Failure, OtpChallengeEntity>(_tooManyRequests);

      await subject.add(const VerifyCodeResendRequested());

      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(
          phone: _phone,
          verifyStatus: RequestStatus.failure,
          verifyFailure: _invalidCode,
          resendStatus: RequestStatus.loading,
        ),
        const VerifyCodeState(
          phone: _phone,
          verifyStatus: RequestStatus.failure,
          verifyFailure: _invalidCode,
          resendStatus: RequestStatus.failure,
          resendFailure: _tooManyRequests,
        ),
      ]);
      expect(subject.bloc.state.canResend, isTrue);

      await subject.close();
    });

    testWidgets('a second resend while sending is dropped', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.holdSendCode = true;

      await subject.add(const VerifyCodeResendRequested());
      await subject.add(const VerifyCodeResendRequested());

      expect(subject.repository.sentPhones, hasLength(1));
      expect(subject.bloc.state.canResend, isFalse);

      subject.repository.heldSendCodes.single.complete(
        Right<Failure, OtpChallengeEntity>(
          subject.repository.challengeFor(_phone),
        ),
      );
      await tester.pump();
      await subject.close();
    });

    testWidgets('verify is ignored while a resend is loading', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.holdSendCode = true;
      await subject.add(const VerifyCodeResendRequested());

      await subject.add(const VerifyCodeChanged('123456'));

      expect(subject.bloc.state.code, '123456');
      expect(subject.bloc.state.canSubmit, isFalse);
      expect(subject.bloc.state.verifyStatus, RequestStatus.initial);

      await subject.add(const VerifyCodeSubmitted());
      expect(subject.repository.verifyCalls, isEmpty);

      subject.repository.heldSendCodes.single.complete(
        Right<Failure, OtpChallengeEntity>(
          subject.repository.challengeFor(_phone),
        ),
      );
      await tester.pump();

      expect(subject.bloc.state.code, isEmpty);
      expect(subject.repository.verifyCalls, isEmpty);

      await subject.close();
    });

    testWidgets('resend is ignored while verify is loading', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.holdVerifyCode = true;
      await subject.add(const VerifyCodeChanged('123456'));

      expect(subject.bloc.state.canResend, isFalse);
      await subject.add(const VerifyCodeResendRequested());

      expect(subject.repository.sentPhones, isEmpty);

      subject.repository.heldVerifyCodes.single.complete(voidSuccess);
      await tester.pump();
      await subject.close();
    });

    testWidgets('closing while sending emits nothing more', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.holdSendCode = true;
      await subject.add(const VerifyCodeResendRequested());

      await subject.close();
      subject.repository.heldSendCodes.single.complete(
        Right<Failure, OtpChallengeEntity>(
          subject.repository.challengeFor(_phone),
        ),
      );
      await tester.pump(const Duration(seconds: 5));

      expect(
        subject.states.map((VerifyCodeState s) => s.resendStatus),
        <RequestStatus>[RequestStatus.loading],
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('code entry and verify', () {
    testWidgets('keeps digits only, at most six', (WidgetTester tester) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);

      await subject.add(const VerifyCodeChanged('1a2-3 '));
      expect(subject.bloc.state.code, '123');

      subject.repository.holdVerifyCode = true;
      await subject.add(const VerifyCodeChanged('12345678'));
      expect(subject.bloc.state.code, '123456');
      expect(subject.repository.verifyCalls.single.code, '123456');

      subject.repository.heldVerifyCodes.single.complete(voidSuccess);
      await tester.pump();
      await subject.close();
    });

    testWidgets('the sixth digit submits exactly once', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);

      await subject.add(const VerifyCodeChanged('12345'));
      expect(subject.repository.verifyCalls, isEmpty);

      await subject.add(const VerifyCodeChanged('123456'));
      await subject.add(const VerifyCodeChanged('123456'));

      expect(subject.repository.verifyCalls, <({String phone, String code})>[
        (phone: _phone, code: '123456'),
      ]);
      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(phone: _phone, code: '12345'),
        const VerifyCodeState(phone: _phone, code: '123456'),
        const VerifyCodeState(
          phone: _phone,
          code: '123456',
          verifyStatus: RequestStatus.loading,
        ),
        const VerifyCodeState(
          phone: _phone,
          code: '123456',
          verifyStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.bloc.state.canSubmit, isFalse);

      await subject.close();
    });

    testWidgets('after success neither typing nor submit verifies again', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      await subject.add(const VerifyCodeChanged('123456'));

      await subject.add(const VerifyCodeChanged('654321'));
      await subject.add(const VerifyCodeSubmitted());

      expect(subject.repository.verifyCalls, hasLength(1));
      expect(subject.bloc.state.verifyStatus, RequestStatus.success);

      await subject.close();
    });

    testWidgets('a code change while verifying is ignored', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.holdVerifyCode = true;
      await subject.add(const VerifyCodeChanged('123456'));
      subject.states.clear();

      await subject.add(const VerifyCodeChanged('12345'));
      await subject.add(const VerifyCodeChanged('654321'));

      expect(subject.states, isEmpty);
      expect(subject.bloc.state.code, '123456');
      expect(subject.repository.verifyCalls, hasLength(1));

      subject.repository.heldVerifyCodes.single.complete(voidSuccess);
      await tester.pump();
      await subject.close();
    });

    testWidgets('a failure clears the code and keeps the failure', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      subject.repository.verifyCodeResult = const Left<Failure, void>(
        _invalidCode,
      );

      await subject.add(const VerifyCodeChanged('123456'));

      expect(
        subject.states.last,
        const VerifyCodeState(
          phone: _phone,
          verifyStatus: RequestStatus.failure,
          verifyFailure: _invalidCode,
        ),
      );

      await subject.close();
    });

    testWidgets('changing the code after a failure returns to initial', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.startWithVerifyFailure();

      await subject.add(const VerifyCodeChanged('4'));

      expect(subject.states, <VerifyCodeState>[
        const VerifyCodeState(phone: _phone, code: '4'),
      ]);

      await subject.close();
    });

    testWidgets('a retry after a failure verifies the new code', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.startWithVerifyFailure();

      await subject.add(const VerifyCodeChanged('482913'));

      expect(subject.repository.verifyCalls.last.code, '482913');
      expect(subject.bloc.state.verifyStatus, RequestStatus.success);

      await subject.close();
    });

    testWidgets('an incomplete manual submit fails with invalid_code', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(Duration.zero);
      await subject.add(const VerifyCodeChanged('123'));

      await subject.add(const VerifyCodeSubmitted());

      expect(subject.bloc.state.verifyFailure, _invalidCode);
      expect(subject.bloc.state.code, isEmpty);
      expect(subject.repository.verifyCalls, isEmpty);

      await subject.close();
    });

    testWidgets('closing while verifying emits nothing more', (
      WidgetTester tester,
    ) async {
      final _Subject subject = _Subject(tester);
      await subject.start(const Duration(seconds: 30));
      subject.repository.holdVerifyCode = true;
      await subject.add(const VerifyCodeChanged('123456'));
      final int emitted = subject.states.length;

      await subject.close();
      subject.repository.heldVerifyCodes.single.complete(
        const Left<Failure, void>(_invalidCode),
      );
      await tester.pump(const Duration(seconds: 3));

      expect(subject.states, hasLength(emitted));
      expect(subject.bloc.state.verifyStatus, RequestStatus.loading);
      expect(tester.takeException(), isNull);
    });
  });

  group('VerifyCodeState.copyWith', () {
    test('reset flags win over supplied failures', () {
      const VerifyCodeState state = VerifyCodeState(
        verifyFailure: _invalidCode,
        resendFailure: _tooManyRequests,
      );

      final VerifyCodeState next = state.copyWith(
        verifyFailure: _invalidCode,
        resetVerifyFailure: true,
        resendFailure: _tooManyRequests,
        resetResendFailure: true,
      );

      expect(next.verifyFailure, isNull);
      expect(next.resendFailure, isNull);
    });
  });
}
