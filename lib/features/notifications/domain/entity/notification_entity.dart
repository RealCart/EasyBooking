import 'package:equatable/equatable.dart';

/// What a notification is about. It decides what
/// [NotificationEntity.targetId] identifies.
enum NotificationKind {
  /// Two bookings overlap; the target is the calendar conflict.
  bookingConflict,

  /// A channel calendar failed to sync; the target is the property.
  syncFailed,

  /// A guest has not signed a contract; the target is the contract.
  contractUnsigned,

  /// A guest signed a contract; the target is the contract.
  contractSigned,

  /// A guest arrives soon; the target is the booking.
  arrivalSoon,

  /// A property went live; the target is the property.
  propertyPublished;

  /// Needs the owner's action to avoid losing a booking.
  bool get isImportant {
    return this == bookingConflict || this == syncFailed;
  }

  bool get isContract => this == contractUnsigned || this == contractSigned;
}

final class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.targetId,
    required this.isRead,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String targetId;
  final bool isRead;

  /// This notification after it was read.
  NotificationEntity asRead() {
    return NotificationEntity(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      targetId: targetId,
      isRead: true,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    kind,
    title,
    body,
    createdAt,
    targetId,
    isRead,
  ];
}
