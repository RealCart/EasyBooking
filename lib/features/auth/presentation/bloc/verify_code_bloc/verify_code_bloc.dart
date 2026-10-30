import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';

part 'verify_code_event.dart';
part 'verify_code_state.dart';

final class VerifyCodeBloc extends Bloc<VerifyCodeEvent, VerifyCodeState> {
  VerifyCodeBloc({required this._verifyCode, required this._sendCode})
    : super(const VerifyCodeState()) {
    on<VerifyCodeStarted>(_onStarted);
    on<VerifyCodeChanged>(_onCodeChanged);
    on<VerifyCodeSubmitted>(_onSubmitted, transformer: droppable());
    on<VerifyCodeResendRequested>(_onResendRequested, transformer: droppable());
    on<VerifyCodeTimerTicked>(_onTimerTicked);
  }

  static const Duration _tick = Duration(seconds: 1);

  final VerifyCodeUsecase _verifyCode;
  final SendCodeUsecase _sendCode;

  Timer? _timer;

  void _onStarted(VerifyCodeStarted event, Emitter<VerifyCodeState> emit) {
    final Duration resendAfter = _nonNegative(event.resendAfter);
    emit(state.copyWith(phone: event.phone, resendAvailableIn: resendAfter));
    _restartCountdown(resendAfter);
  }

  void _onCodeChanged(VerifyCodeChanged event, Emitter<VerifyCodeState> emit) {
    // A failure clears the code, so a digit typed during verify would be
    // wiped and never sent.
    if (state.verifyStatus.isLoading) {
      return;
    }
    final String digits = PhoneNumber.digitsOnly(event.code);
    final String code = digits.length > Validators.otpLength
        ? digits.substring(0, Validators.otpLength)
        : digits;
    if (code == state.code) {
      return;
    }
    emit(
      state.copyWith(
        code: code,
        verifyStatus: state.verifyStatus.isFailure
            ? RequestStatus.initial
            : null,
        resetVerifyFailure: true,
      ),
    );
    if (code.length == Validators.otpLength &&
        !state.verifyStatus.isLoading &&
        !isClosed) {
      add(const VerifyCodeSubmitted());
    }
  }

  Future<void> _onSubmitted(
    VerifyCodeSubmitted event,
    Emitter<VerifyCodeState> emit,
  ) async {
    // After success the router leaves the screen; never sign in twice.
    // Verify and resend are mutually exclusive: resend success clears the
    // code.
    if (state.verifyStatus.isLoading ||
        state.verifyStatus.isSuccess ||
        state.resendStatus.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        verifyStatus: RequestStatus.loading,
        resetVerifyFailure: true,
      ),
    );

    final Either<Failure, void> result = await _verifyCode(
      VerifyCodeParams(phone: state.phone, code: state.code),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(
          state.copyWith(
            code: '',
            verifyStatus: RequestStatus.failure,
            verifyFailure: failure,
          ),
        );
      case Right<Failure, void>():
        emit(state.copyWith(verifyStatus: RequestStatus.success));
    }
  }

  Future<void> _onResendRequested(
    VerifyCodeResendRequested event,
    Emitter<VerifyCodeState> emit,
  ) async {
    if (!state.canResend) {
      return;
    }
    emit(
      state.copyWith(
        resendStatus: RequestStatus.loading,
        resetResendFailure: true,
      ),
    );

    final Either<Failure, OtpChallengeEntity> result = await _sendCode(
      state.phone,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, OtpChallengeEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            resendStatus: RequestStatus.failure,
            resendFailure: failure,
          ),
        );
      case Right<Failure, OtpChallengeEntity>(
        value: final OtpChallengeEntity challenge,
      ):
        final Duration resendAfter = _nonNegative(challenge.resendAfter);
        emit(
          state.copyWith(
            code: '',
            verifyStatus: state.verifyStatus.isFailure
                ? RequestStatus.initial
                : null,
            resetVerifyFailure: true,
            resendStatus: RequestStatus.success,
            resendAvailableIn: resendAfter,
          ),
        );
        _restartCountdown(resendAfter);
    }
  }

  void _onTimerTicked(
    VerifyCodeTimerTicked event,
    Emitter<VerifyCodeState> emit,
  ) {
    final Duration left = state.resendAvailableIn - _tick;
    if (left <= Duration.zero) {
      _cancelCountdown();
      emit(state.copyWith(resendAvailableIn: Duration.zero));
      return;
    }
    emit(state.copyWith(resendAvailableIn: left));
  }

  void _restartCountdown(Duration resendAfter) {
    _cancelCountdown();
    if (resendAfter <= Duration.zero || isClosed) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) {
      if (isClosed) {
        _cancelCountdown();
        return;
      }
      add(const VerifyCodeTimerTicked());
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _timer = null;
  }

  static Duration _nonNegative(Duration duration) {
    return duration < Duration.zero ? Duration.zero : duration;
  }

  @override
  Future<void> close() {
    _cancelCountdown();
    return super.close();
  }
}
