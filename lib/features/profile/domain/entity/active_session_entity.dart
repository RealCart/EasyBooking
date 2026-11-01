import 'package:equatable/equatable.dart';

enum SessionDeviceType { phone, tablet, computer }

/// A device signed in to the account («Активные сеансы»).
final class ActiveSessionEntity extends Equatable {
  const ActiveSessionEntity({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.city,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final String id;

  /// Such as `iPhone 15 Pro`.
  final String deviceName;
  final SessionDeviceType deviceType;

  /// Where the device was last seen, such as `Алматы`.
  final String city;
  final DateTime lastActiveAt;

  /// This device («Этот»).
  final bool isCurrent;

  @override
  List<Object?> get props => <Object?>[
    id,
    deviceName,
    deviceType,
    city,
    lastActiveAt,
    isCurrent,
  ];
}
