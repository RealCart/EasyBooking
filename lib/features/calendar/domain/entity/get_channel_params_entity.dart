import 'package:equatable/equatable.dart';

final class GetChannelParamsEntity extends Equatable {
  const GetChannelParamsEntity({required this.channelId});

  final String channelId;

  @override
  List<Object?> get props => <Object?>[channelId];
}
