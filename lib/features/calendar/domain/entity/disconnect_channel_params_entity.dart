import 'package:equatable/equatable.dart';

final class DisconnectChannelParamsEntity extends Equatable {
  const DisconnectChannelParamsEntity({required this.channelId});

  final String channelId;

  @override
  List<Object?> get props => <Object?>[channelId];
}
