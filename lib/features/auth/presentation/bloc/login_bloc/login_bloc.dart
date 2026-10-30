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

part 'login_event.dart';
part 'login_state.dart';

final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this._sendCode}) : super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SendCodeUsecase _sendCode;

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    // Resetting mid-request would re-enable submit while `droppable()` still
    // drops the tap, and the stale result would be discarded: the tap is lost.
    if (state.status.isLoading) {
      return;
    }
    final String phone = PhoneNumber.nationalDigits(event.phone);
    if (phone == state.phone) {
      return;
    }
    emit(
      state.copyWith(
        phone: phone,
        status: RequestStatus.initial,
        resetFailure: true,
        resetChallenge: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status.isLoading) {
      return;
    }
    // The use case validates the number, so an incomplete one submitted from
    // the keyboard still produces an `invalid_phone` failure.
    final String phone = state.phone;
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        resetFailure: true,
        resetChallenge: true,
      ),
    );

    final Either<Failure, OtpChallengeEntity> result = await _sendCode(phone);
    // A phone change while sending resets the state; its result is stale.
    if (emit.isDone || state.phone != phone) {
      return;
    }
    switch (result) {
      case Left<Failure, OtpChallengeEntity>(value: final Failure failure):
        emit(state.copyWith(status: RequestStatus.failure, failure: failure));
      case Right<Failure, OtpChallengeEntity>(
        value: final OtpChallengeEntity challenge,
      ):
        emit(
          state.copyWith(status: RequestStatus.success, challenge: challenge),
        );
    }
  }
}
