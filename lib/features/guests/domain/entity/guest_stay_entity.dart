import 'package:equatable/equatable.dart';

/// Where a stay is relative to the moment the data was produced.
enum GuestStayStatus {
  /// Check-in is still ahead.
  upcoming,

  /// The guest has checked in and not yet checked out.
  current,

  /// Check-out has passed.
  past,
}

/// One booking of a guest in a property.
final class GuestStayEntity extends Equatable {
  const GuestStayEntity({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  /// Opens `AppRoutes.booking`.
  final String bookingId;

  /// Opens `AppRoutes.property`.
  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName], such as `84`.
  final String unit;
  final DateTime checkIn;
  final DateTime checkOut;
  final GuestStayStatus status;

  /// Calendar nights, so a DST change does not shift the count.
  int get nights {
    return DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    ).difference(DateTime.utc(checkIn.year, checkIn.month, checkIn.day)).inDays;
  }

  @override
  List<Object?> get props => <Object?>[
    bookingId,
    propertyId,
    propertyName,
    unit,
    checkIn,
    checkOut,
    status,
  ];
}
