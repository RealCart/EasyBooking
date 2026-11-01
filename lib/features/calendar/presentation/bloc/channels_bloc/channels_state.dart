part of 'channels_bloc.dart';

final class ChannelsState extends Equatable {
  const ChannelsState({
    this.loadStatus = RequestStatus.initial,
    this.overview,
    this.loadFailure,
  });

  final RequestStatus loadStatus;

  /// The last loaded channels; kept while a reload runs.
  final ChannelsOverviewEntity? overview;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  ChannelsState copyWith({
    RequestStatus? loadStatus,
    ChannelsOverviewEntity? overview,
    Failure? loadFailure,
    bool resetLoadFailure = false,
  }) {
    return ChannelsState(
      loadStatus: loadStatus ?? this.loadStatus,
      overview: overview ?? this.overview,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[loadStatus, overview, loadFailure];
}
