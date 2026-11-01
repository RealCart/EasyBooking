import 'package:equatable/equatable.dart';

final class SyncChannelParamsEntity extends Equatable {
  const SyncChannelParamsEntity({required this.channelId});

  final String channelId;

  @override
  List<Object?> get props => <Object?>[channelId];
}
