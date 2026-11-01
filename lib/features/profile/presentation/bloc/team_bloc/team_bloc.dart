import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/remove_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';

part 'team_event.dart';
part 'team_state.dart';

/// «Команда и доступ»: the member list, inviting, and removing members.
final class TeamBloc extends Bloc<TeamEvent, TeamState> {
  TeamBloc({
    required this._getTeam,
    required this._inviteTeamMember,
    required this._removeTeamMember,
  }) : super(const TeamState()) {
    on<TeamRequested>(_onRequested, transformer: restartable());
    on<TeamInviteStarted>(_onInviteStarted);
    on<TeamInviteFieldEdited>(_onInviteFieldEdited);
    on<TeamInviteSubmitted>(_onInviteSubmitted, transformer: droppable());
    on<TeamMemberRemoveRequested>(
      _onMemberRemoveRequested,
      transformer: droppable(),
    );
  }

  /// Fields of the invite form. A server error keyed by anything else
  /// would be invisible, so it is also reported as
  /// [TeamState.inviteFailure].
  static const Set<String> _inviteFields = <String>{
    ProfileFields.firstName,
    ProfileFields.lastName,
    ProfileFields.phone,
  };

  final GetTeamUsecase _getTeam;
  final InviteTeamMemberUsecase _inviteTeamMember;
  final RemoveTeamMemberUsecase _removeTeamMember;

  /// Bumped by every successful write, so a load that started earlier does
  /// not replace the newer member list.
  int _writeCount = 0;

  Future<void> _onRequested(
    TeamRequested event,
    Emitter<TeamState> emit,
  ) async {
    final int writeCount = _writeCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, List<TeamMemberEntity>> result = await _getTeam(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    if (writeCount != _writeCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, List<TeamMemberEntity>>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, List<TeamMemberEntity>>(
        value: final List<TeamMemberEntity> members,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            members: List<TeamMemberEntity>.unmodifiable(members),
          ),
        );
    }
  }

  /// Hides the server error of the edited invite field and the general
  /// invite failure.
  void _onInviteStarted(TeamInviteStarted event, Emitter<TeamState> emit) {
    // A running invite keeps its result; its sheet is still open.
    if (state.inviteStatus.isLoading) {
      return;
    }
    emit(
      state.copyWith(
        inviteStatus: RequestStatus.initial,
        inviteFieldErrors: const <String, String>{},
        resetInviteFailure: true,
      ),
    );
  }

  void _onInviteFieldEdited(
    TeamInviteFieldEdited event,
    Emitter<TeamState> emit,
  ) {
    final bool hasFieldError = state.inviteFieldErrors.containsKey(
      event.field,
    );
    if (!hasFieldError &&
        state.inviteFailure == null &&
        !state.inviteStatus.isFailure) {
      return;
    }
    final Map<String, String> fieldErrors = hasFieldError
        ? Map<String, String>.unmodifiable(
            Map<String, String>.of(state.inviteFieldErrors)
              ..remove(event.field),
          )
        : state.inviteFieldErrors;
    emit(
      state.copyWith(
        inviteStatus: state.inviteStatus.isFailure
            ? RequestStatus.initial
            : null,
        resetInviteFailure: true,
        inviteFieldErrors: fieldErrors,
      ),
    );
  }

  Future<void> _onInviteSubmitted(
    TeamInviteSubmitted event,
    Emitter<TeamState> emit,
  ) async {
    emit(
      state.copyWith(
        inviteStatus: RequestStatus.loading,
        resetInviteFailure: true,
        inviteFieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, List<TeamMemberEntity>> result =
        await _inviteTeamMember(event.params);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, List<TeamMemberEntity>>(
            value: final ValidationFailure failure,
          )
          when failure.fieldErrors.isNotEmpty:
        final bool isDisplayed = failure.fieldErrors.keys.any(
          _inviteFields.contains,
        );
        emit(
          state.copyWith(
            inviteStatus: RequestStatus.failure,
            inviteFieldErrors: Map<String, String>.unmodifiable(
              failure.fieldErrors,
            ),
            inviteFailure: isDisplayed ? null : failure,
          ),
        );
      case Left<Failure, List<TeamMemberEntity>>(value: final Failure failure):
        emit(
          state.copyWith(
            inviteStatus: RequestStatus.failure,
            inviteFailure: failure,
          ),
        );
      case Right<Failure, List<TeamMemberEntity>>(
        value: final List<TeamMemberEntity> members,
      ):
        _writeCount += 1;
        emit(
          state.copyWith(
            inviteStatus: RequestStatus.success,
            members: List<TeamMemberEntity>.unmodifiable(members),
          ),
        );
    }
  }

  Future<void> _onMemberRemoveRequested(
    TeamMemberRemoveRequested event,
    Emitter<TeamState> emit,
  ) async {
    emit(
      state.copyWith(
        removeStatus: RequestStatus.loading,
        removingMemberId: event.memberId,
        resetRemoveFailure: true,
      ),
    );

    final Either<Failure, List<TeamMemberEntity>> result =
        await _removeTeamMember(
          RemoveTeamMemberParamsEntity(memberId: event.memberId),
        );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, List<TeamMemberEntity>>(value: final Failure failure):
        emit(
          state.copyWith(
            removeStatus: RequestStatus.failure,
            removeFailure: failure,
            resetRemovingMemberId: true,
          ),
        );
      case Right<Failure, List<TeamMemberEntity>>(
        value: final List<TeamMemberEntity> members,
      ):
        _writeCount += 1;
        emit(
          state.copyWith(
            removeStatus: RequestStatus.success,
            members: List<TeamMemberEntity>.unmodifiable(members),
            resetRemovingMemberId: true,
          ),
        );
    }
  }
}
