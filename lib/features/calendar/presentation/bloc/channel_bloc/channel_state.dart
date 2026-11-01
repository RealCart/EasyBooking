part of 'channel_bloc.dart';

final class ChannelState extends Equatable {
  const ChannelState({
    this.channelId = '',
    this.loadStatus = RequestStatus.initial,
    this.channel,
    this.loadFailure,
    this.syncStatus = RequestStatus.initial,
    this.syncFailure,
    this.disconnectStatus = RequestStatus.initial,
    this.disconnectFailure,
  });

  /// The requested channel, for retrying a failed load.
  final String channelId;

  final RequestStatus loadStatus;
  final ChannelEntity? channel;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus syncStatus;

  /// The failure of the last sync, for a one-off message.
  final Failure? syncFailure;

  /// [RequestStatus.success] means the channel is off and the screen should
  /// leave.
  final RequestStatus disconnectStatus;

  /// The failure of the last disconnect, for a one-off message.
  final Failure? disconnectFailure;

  /// A sync or disconnect is running; both buttons should be disabled.
  bool get isBusy => syncStatus.isLoading || disconnectStatus.isLoading;

  ChannelState copyWith({
    String? channelId,
    RequestStatus? loadStatus,
    ChannelEntity? channel,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? syncStatus,
    Failure? syncFailure,
    bool resetSyncFailure = false,
    RequestStatus? disconnectStatus,
    Failure? disconnectFailure,
    bool resetDisconnectFailure = false,
  }) {
    return ChannelState(
      channelId: channelId ?? this.channelId,
      loadStatus: loadStatus ?? this.loadStatus,
      channel: channel ?? this.channel,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      syncStatus: syncStatus ?? this.syncStatus,
      syncFailure: resetSyncFailure ? null : syncFailure ?? this.syncFailure,
      disconnectStatus: disconnectStatus ?? this.disconnectStatus,
      disconnectFailure: resetDisconnectFailure
          ? null
          : disconnectFailure ?? this.disconnectFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    channelId,
    loadStatus,
    channel,
    loadFailure,
    syncStatus,
    syncFailure,
    disconnectStatus,
    disconnectFailure,
  ];
}
