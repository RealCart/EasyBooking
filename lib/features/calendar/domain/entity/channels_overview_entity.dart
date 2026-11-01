import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';

/// Every channel of the host, for «Каналы».
final class ChannelsOverviewEntity extends Equatable {
  const ChannelsOverviewEntity({
    required this.channels,
    required this.checkedAt,
    required this.receivedAt,
  });

  /// In display order.
  final List<ChannelEntity> channels;

  /// The last check of any channel («Последняя проверка 09:38»).
  final DateTime checkedAt;

  /// The source's current time when it answered: the reference for
  /// relative labels, such as today's check showing only its time.
  final DateTime receivedAt;

  /// Channels that are not [ChannelStatus.disconnected] («3 подключения»).
  int get activeChannelCount {
    return channels
        .where(
          (ChannelEntity channel) =>
              channel.status != ChannelStatus.disconnected,
        )
        .length;
  }

  /// Distinct properties linked to any channel («4 объекта»).
  int get propertyCount {
    return <String>{
      for (final ChannelEntity channel in channels)
        for (final ChannelConnectionEntity connection in channel.connections)
          connection.propertyId,
    }.length;
  }

  @override
  List<Object?> get props => <Object?>[channels, checkedAt, receivedAt];
}
