import 'package:equatable/equatable.dart';

/// The booking a contract covers.
final class ContractStayEntity extends Equatable {
  const ContractStayEntity({
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.imageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.pricePerNight,
    required this.deposit,
  });

  final String bookingId;
  final String propertyId;
  final String propertyName;

  /// Apartment number within [propertyName].
  final String unit;
  final String imageUrl;

  /// Check-in date and time; its time is the check-in hour.
  final DateTime checkIn;

  /// Check-out date and time; its time is the check-out hour.
  final DateTime checkOut;

  /// Whole tenge.
  final int pricePerNight;

  /// Refundable deposit in whole tenge.
  final int deposit;

  /// Calendar nights between [checkIn] and [checkOut].
  int get nights {
    final DateTime start = DateTime.utc(
      checkIn.year,
      checkIn.month,
      checkIn.day,
    );
    final DateTime end = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );
    return end.difference(start).inDays;
  }

  /// Rent for the whole stay in whole tenge, without the [deposit].
  int get rentTotal => pricePerNight * nights;

  @override
  List<Object?> get props => <Object?>[
    bookingId,
    propertyId,
    propertyName,
    unit,
    imageUrl,
    checkIn,
    checkOut,
    pricePerNight,
    deposit,
  ];
}
