import 'package:equatable/equatable.dart';

enum HomeStayStatus {
  /// Everything is prepared for the arrival.
  ready,

  /// The guest has not signed the contract yet.
  awaitingContract,

  /// Cleaning after the departure is booked.
  cleaningScheduled,

  /// The guest signed the contract.
  contractSigned,
}

/// A guest stay shown on the home screen.
final class HomeStayEntity extends Equatable {
  const HomeStayEntity({
    required this.propertyId,
    required this.propertyName,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.imageUrl,
  });

  final String propertyId;
  final String propertyName;

  /// Photo of the property; `null` when it has none.
  final String? imageUrl;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final HomeStayStatus status;

  /// Calendar nights, so a DST change does not shift the count.
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

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    propertyName,
    imageUrl,
    guestName,
    checkIn,
    checkOut,
    status,
  ];
}
