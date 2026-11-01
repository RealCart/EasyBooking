part of 'team_bloc.dart';

sealed class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the team: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class TeamRequested extends TeamEvent {
  const TeamRequested();
}

/// The invite form was opened; clears the result of the previous invite so
/// the new form starts empty and enabled.
final class TeamInviteStarted extends TeamEvent {
  const TeamInviteStarted();
}

/// The user edited invite form [field] (a `ProfileFields` key); clears its
/// server error.
final class TeamInviteFieldEdited extends TeamEvent {
  const TeamInviteFieldEdited(this.field);

  final String field;

  @override
  List<Object?> get props => <Object?>[field];
}

/// «Пригласить» with the validated invite form.
final class TeamInviteSubmitted extends TeamEvent {
  const TeamInviteSubmitted(this.params);

  final InviteTeamMemberParamsEntity params;

  @override
  List<Object?> get props => <Object?>[params];
}

/// The user confirmed revoking the access of [memberId].
final class TeamMemberRemoveRequested extends TeamEvent {
  const TeamMemberRemoveRequested(this.memberId);

  final String memberId;

  @override
  List<Object?> get props => <Object?>[memberId];
}
