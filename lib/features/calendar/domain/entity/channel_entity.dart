import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';

enum ChannelStatus {
  /// Every connection works («Подключён»).
  connected,

  /// At least one connection failed («Ошибка»).
  failed,

  /// The channel has no calendar import: bookings are entered by hand and
  /// EasyBooking only exports («Ручные брони · экспорт iCal»).
  manual,

  /// The host turned the channel off; it has no connections.
  disconnected,
}

/// A booking channel, such as Airbnb, and its property calendars.
final class ChannelEntity extends Equatable {
  const ChannelEntity({
    required this.id,
    required this.name,
    required this.status,
    required this.connections,
    required this.checkInterval,
    required this.receivedAt,
    this.lastSyncedAt,
    this.nextCheckAt,
  });

  final String id;

  /// Display name, such as `Booking.com`.
  final String name;
  final ChannelStatus status;

  /// One per property, in the properties' order; empty for a
  /// [ChannelStatus.manual] or [ChannelStatus.disconnected] channel.
  final List<ChannelConnectionEntity> connections;

  /// How often EasyBooking checks the import links («каждые 15 минут»).
  final Duration checkInterval;

  /// The source's current time when it answered: the reference for
  /// relative labels («сегодня в 09:38», «через 8 минут»).
  final DateTime receivedAt;

  /// The last successful import; `null` when there never was one.
  final DateTime? lastSyncedAt;

  /// The next automatic check; `null` when nothing is imported.
  final DateTime? nextCheckAt;

  int get propertyCount => connections.length;

  /// Connections that need the host's attention («требует внимания»).
  List<ChannelConnectionEntity> get failedConnections {
    return List<ChannelConnectionEntity>.unmodifiable(
      connections.where(
        (ChannelConnectionEntity connection) => connection.isFailed,
      ),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    status,
    connections,
    checkInterval,
    receivedAt,
    lastSyncedAt,
    nextCheckAt,
  ];
}
