import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/conflict_booking_entity.dart';

/// Two bookings of one property that overlap («Пересечение бронирований»).
final class CalendarConflictEntity extends Equatable {
  const CalendarConflictEntity({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.overlapStart,
    required this.overlapEnd,
    required this.bookings,
    required this.position,
    required this.total,
    required this.receivedAt,
    this.keptBookingId,
  });

  final String id;
  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName].
  final String unit;

  /// First overlapping day, at midnight.
  final DateTime overlapStart;

  /// Last overlapping day, at midnight («24–25 октября»).
  final DateTime overlapEnd;

  /// The overlapping bookings, the channel's first.
  final List<ConflictBookingEntity> bookings;

  /// This conflict's number among all of them, from 1 («1 из 1»).
  final int position;

  /// How many conflicts there are.
  final int total;

  /// The source's current time when it answered: the reference for
  /// relative labels («Создана вчера»).
  final DateTime receivedAt;

  /// The booking the host kept; `null` until the conflict is resolved.
  final String? keptBookingId;

  bool get isResolved => keptBookingId != null;

  @override
  List<Object?> get props => <Object?>[
    id,
    propertyId,
    propertyName,
    unit,
    overlapStart,
    overlapEnd,
    bookings,
    position,
    total,
    receivedAt,
    keptBookingId,
  ];
}
