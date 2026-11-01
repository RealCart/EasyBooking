import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/set_biometric_login_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';

part 'security_event.dart';
part 'security_state.dart';

/// «Безопасность»: the overview, the Face ID switch, and ending the other
/// sessions.
final class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc({
    required this._getSecurityOverview,
    required this._setBiometricLogin,
    required this._terminateOtherSessions,
  }) : super(const SecurityState()) {
    on<SecurityRequested>(_onRequested, transformer: restartable());
    on<SecurityBiometricLoginToggled>(
      _onBiometricLoginToggled,
      transformer: droppable(),
    );
    on<SecurityOtherSessionsTerminateRequested>(
      _onOtherSessionsTerminateRequested,
      transformer: droppable(),
    );
  }

  final GetSecurityOverviewUsecase _getSecurityOverview;
  final SetBiometricLoginUsecase _setBiometricLogin;
  final TerminateOtherSessionsUsecase _terminateOtherSessions;

  /// Bumped by every successful write, so a load that started earlier does
  /// not replace the newer overview.
  int _writeCount = 0;

  Future<void> _onRequested(
    SecurityRequested event,
    Emitter<SecurityState> emit,
  ) async {
    final int writeCount = _writeCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, SecurityOverviewEntity> result =
        await _getSecurityOverview(const NoParams());
    if (emit.isDone) {
      return;
    }
    if (writeCount != _writeCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, SecurityOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, SecurityOverviewEntity>(
        value: final SecurityOverviewEntity overview,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, overview: overview),
        );
    }
  }

  /// The switch shows the saved value: it flips after the source confirmed
  /// the write and stays when the write fails.
  Future<void> _onBiometricLoginToggled(
    SecurityBiometricLoginToggled event,
    Emitter<SecurityState> emit,
  ) async {
    emit(
      state.copyWith(
        biometricStatus: RequestStatus.loading,
        resetBiometricFailure: true,
      ),
    );

    final Either<Failure, SecurityOverviewEntity> result =
        await _setBiometricLogin(
          SetBiometricLoginParamsEntity(isEnabled: event.isEnabled),
        );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, SecurityOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            biometricStatus: RequestStatus.failure,
            biometricFailure: failure,
          ),
        );
      case Right<Failure, SecurityOverviewEntity>(
        value: final SecurityOverviewEntity overview,
      ):
        _writeCount += 1;
        emit(
          state.copyWith(
            biometricStatus: RequestStatus.success,
            overview: overview,
          ),
        );
    }
  }

  Future<void> _onOtherSessionsTerminateRequested(
    SecurityOtherSessionsTerminateRequested event,
    Emitter<SecurityState> emit,
  ) async {
    emit(
      state.copyWith(
        terminateStatus: RequestStatus.loading,
        resetTerminateFailure: true,
      ),
    );

    final Either<Failure, SecurityOverviewEntity> result =
        await _terminateOtherSessions(const NoParams());
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, SecurityOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            terminateStatus: RequestStatus.failure,
            terminateFailure: failure,
          ),
        );
      case Right<Failure, SecurityOverviewEntity>(
        value: final SecurityOverviewEntity overview,
      ):
        _writeCount += 1;
        emit(
          state.copyWith(
            terminateStatus: RequestStatus.success,
            overview: overview,
          ),
        );
    }
  }
}
