import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

final class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this._getProfile, required this._signOut})
    : super(const ProfileState()) {
    // Latest wins: a refresh replaces a load that is still running.
    on<ProfileRequested>(_onRequested, transformer: restartable());
    on<ProfileSignOutRequested>(_onSignOutRequested, transformer: droppable());
  }

  final GetProfileUsecase _getProfile;
  final SignOutUsecase _signOut;

  /// Keeps the shown profile while loading and after a failed refresh.
  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, ProfileEntity> result = await _getProfile(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ProfileEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, ProfileEntity>(value: final ProfileEntity profile):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, profile: profile),
        );
    }
  }

  /// On success the router redirect leaves the screen, so nothing else
  /// happens here.
  Future<void> _onSignOutRequested(
    ProfileSignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.signOutStatus.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        signOutStatus: RequestStatus.loading,
        resetSignOutFailure: true,
      ),
    );

    final Either<Failure, void> result = await _signOut(const NoParams());
    if (emit.isDone) {
      return;
    }
    // The session signs out in memory before the storage is cleared, so the
    // router leaves even when clearing fails; report it anyway.
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(
          state.copyWith(
            signOutStatus: RequestStatus.failure,
            signOutFailure: failure,
          ),
        );
      case Right<Failure, void>():
        emit(state.copyWith(signOutStatus: RequestStatus.success));
    }
  }
}
