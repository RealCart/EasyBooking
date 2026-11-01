import 'package:equatable/equatable.dart';

/// Default stay terms of a property, applied to new bookings.
final class PropertyTermsEntity extends Equatable {
  const PropertyTermsEntity({
    required this.pricePerNight,
    required this.deposit,
    required this.checkInTime,
    required this.checkOutTime,
    required this.minNights,
    required this.cleaningFee,
  });

  /// Base price in whole tenge.
  final int pricePerNight;

  /// Security deposit in whole tenge; `0` when none is taken.
  final int deposit;

  /// Earliest check-in, as the time since midnight (14:00 is 14 hours).
  final Duration checkInTime;

  /// Latest check-out, as the time since midnight.
  final Duration checkOutTime;
  final int minNights;

  /// Cleaning fee per stay in whole tenge; `0` when free.
  final int cleaningFee;

  @override
  List<Object?> get props => <Object?>[
    pricePerNight,
    deposit,
    checkInTime,
    checkOutTime,
    minNights,
    cleaningFee,
  ];
}
