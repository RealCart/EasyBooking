import 'package:equatable/equatable.dart';

/// The last import of the external booking calendars.
final class CalendarSyncEntity extends Equatable {
  const CalendarSyncEntity({
    required this.updatedAt,
    required this.channelNames,
    required this.propertyCount,
  });

  final DateTime updatedAt;

  /// Connected booking channels, such as `Booking.com`.
  final List<String> channelNames;

  /// Number of properties whose calendars are synced.
  final int propertyCount;

  @override
  List<Object?> get props => <Object?>[updatedAt, channelNames, propertyCount];
}
