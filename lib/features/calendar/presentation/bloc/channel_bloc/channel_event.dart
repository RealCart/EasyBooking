part of 'channel_bloc.dart';

sealed class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [channelId]: added when the BLoC is created and on retry.
final class ChannelRequested extends ChannelEvent {
  const ChannelRequested(this.channelId);

  final String channelId;

  @override
  List<Object?> get props => <Object?>[channelId];
}

/// «Синхронизировать сейчас». Ignored while a sync or disconnect runs.
final class ChannelSyncRequested extends ChannelEvent {
  const ChannelSyncRequested();
}

/// «Отключить», after the host confirmed it. Ignored while a sync or
/// disconnect runs.
final class ChannelDisconnectRequested extends ChannelEvent {
  const ChannelDisconnectRequested();
}
