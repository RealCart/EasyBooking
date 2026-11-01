import 'package:equatable/equatable.dart';

/// The next guest of a property.
final class UpcomingStayEntity extends Equatable {
  const UpcomingStayEntity({
    required this.bookingId,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
  });

  final String bookingId;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;

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
    guestName,
    checkIn,
    checkOut,
    guestCount,
  ];
}
