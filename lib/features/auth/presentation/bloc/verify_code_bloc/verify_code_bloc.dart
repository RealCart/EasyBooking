import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/send_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/verify_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';

part 'verify_code_event.dart';
part 'verify_code_state.dart';

final class VerifyCodeBloc extends Bloc<VerifyCodeEvent, VerifyCodeState> {
  VerifyCodeBloc({required this._verifyCode, required this._sendCode})
    : super(const VerifyCodeState()) {
    on<VerifyCodeStarted>(_onStarted);
    on<VerifyCodeEdited>(_onEdited);
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

  /// Typing after a failed check hides its error.
  void _onEdited(VerifyCodeEdited event, Emitter<VerifyCodeState> emit) {
    if (!state.verifyStatus.isFailure) {
      return;
    }
    emit(
      state.copyWith(
        verifyStatus: RequestStatus.initial,
        resetVerifyFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    VerifyCodeSubmitted event,
    Emitter<VerifyCodeState> emit,
  ) async {
    // After success the router leaves the screen; never sign in twice.
    // Verify and resend are mutually exclusive: the screen clears the code
    // after a successful resend.
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

    final Either<Failure, void> result = await _verifyCode(event.params);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(
          state.copyWith(
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
      SendCodeParamsEntity(phone: state.phone),
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
