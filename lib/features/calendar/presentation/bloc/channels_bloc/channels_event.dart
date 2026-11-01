part of 'channels_bloc.dart';

sealed class ChannelsEvent extends Equatable {
  const ChannelsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the channels: added when the BLoC is created, on retry, on
/// pull-to-refresh, and after returning from a channel that changed.
final class ChannelsRequested extends ChannelsEvent {
  const ChannelsRequested();
}
