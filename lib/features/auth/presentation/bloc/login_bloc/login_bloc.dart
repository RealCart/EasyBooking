import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/send_code_params_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this._sendCode}) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted, transformer: droppable());
  }

  final SendCodeUsecase _sendCode;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.status.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        status: RequestStatus.loading,
        resetFailure: true,
        resetChallenge: true,
      ),
    );

    // The phone field is disabled while sending, so the result cannot be
    // stale.
    final Either<Failure, OtpChallengeEntity> result = await _sendCode(
      event.params,
    );
    if (emit.isDone) {
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
