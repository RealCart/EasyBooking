part of 'help_bloc.dart';

final class HelpState extends Equatable {
  const HelpState({
    this.loadStatus = RequestStatus.initial,
    this.helpCenter,
    this.loadFailure,
  });

  final RequestStatus loadStatus;

  /// Everything the screen shows, unfiltered.
  final HelpCenterEntity? helpCenter;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  HelpState copyWith({
    RequestStatus? loadStatus,
    HelpCenterEntity? helpCenter,
    Failure? loadFailure,
    bool resetLoadFailure = false,
  }) {
    return HelpState(
      loadStatus: loadStatus ?? this.loadStatus,
      helpCenter: helpCenter ?? this.helpCenter,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[loadStatus, helpCenter, loadFailure];
}
