part of 'team_bloc.dart';

final class TeamState extends Equatable {
  const TeamState({
    this.loadStatus = RequestStatus.initial,
    this.members = const <TeamMemberEntity>[],
    this.loadFailure,
    this.inviteStatus = RequestStatus.initial,
    this.inviteFailure,
    this.inviteFieldErrors = const <String, String>{},
    this.removeStatus = RequestStatus.initial,
    this.removingMemberId,
    this.removeFailure,
  });

  final RequestStatus loadStatus;

  /// The current user first; replaced after every invite or removal.
  final List<TeamMemberEntity> members;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  /// [RequestStatus.success] means the invitation was sent: close the form.
  final RequestStatus inviteStatus;

  /// An invite failure that does not belong to a field, such as
  /// `ProfileErrorCodes.teamLimitReached` in `ValidationFailure.code`.
  final Failure? inviteFailure;

  /// `ProfileFields` key to a `FieldErrorCodes` field code or
  /// `ProfileErrorCodes.alreadyInTeam`.
  final Map<String, String> inviteFieldErrors;

  final RequestStatus removeStatus;

  /// The member being removed while [removeStatus] is loading.
  final String? removingMemberId;

  /// Set when [removeStatus] is [RequestStatus.failure], such as
  /// `ProfileErrorCodes.cannotRemoveOwner`.
  final Failure? removeFailure;

  TeamState copyWith({
    RequestStatus? loadStatus,
    List<TeamMemberEntity>? members,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? inviteStatus,
    Failure? inviteFailure,
    bool resetInviteFailure = false,
    Map<String, String>? inviteFieldErrors,
    RequestStatus? removeStatus,
    String? removingMemberId,
    bool resetRemovingMemberId = false,
    Failure? removeFailure,
    bool resetRemoveFailure = false,
  }) {
    return TeamState(
      loadStatus: loadStatus ?? this.loadStatus,
      members: members ?? this.members,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      inviteStatus: inviteStatus ?? this.inviteStatus,
      inviteFailure: resetInviteFailure
          ? null
          : inviteFailure ?? this.inviteFailure,
      inviteFieldErrors: inviteFieldErrors ?? this.inviteFieldErrors,
      removeStatus: removeStatus ?? this.removeStatus,
      removingMemberId: resetRemovingMemberId
          ? null
          : removingMemberId ?? this.removingMemberId,
      removeFailure: resetRemoveFailure
          ? null
          : removeFailure ?? this.removeFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    loadStatus,
    members,
    loadFailure,
    inviteStatus,
    inviteFailure,
    inviteFieldErrors,
    removeStatus,
    removingMemberId,
    removeFailure,
  ];
}
