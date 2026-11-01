import 'package:equatable/equatable.dart';

enum CalendarEventKind { checkIn, checkOut }

/// A check-in or check-out on the calendar.
final class CalendarEventEntity extends Equatable {
  const CalendarEventEntity({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.at,
    required this.guestName,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.imageUrl,
    required this.nights,
    this.isContractSigned,
    this.note,
  });

  final String id;
  final String bookingId;
  final CalendarEventKind kind;
  final DateTime at;

  /// First name, as shown on the calendar.
  final String guestName;
  final String propertyId;
  final String propertyName;

  /// Apartment number within [propertyName].
  final String unit;
  final String imageUrl;

  /// Nights of the stay this event belongs to.
  final int nights;

  /// Whether the guest signed the contract; `null` when no contract is
  /// needed, as for a departure.
  final bool? isContractSigned;

  /// A remark from the host, such as where the keys are left.
  final String? note;

  @override
  List<Object?> get props => <Object?>[
    id,
    bookingId,
    kind,
    at,
    guestName,
    propertyId,
    propertyName,
    unit,
    imageUrl,
    nights,
    isContractSigned,
    note,
  ];
}
