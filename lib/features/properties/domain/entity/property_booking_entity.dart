import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';

enum PropertyBookingStatus {
  /// Booked, but neither confirmed by a channel nor paid yet. A direct
  /// booking ([PropertyBookingEntity.channel] is `null`) in this status is
  /// shown as «Напрямую» in the design.
  pending,

  /// Confirmed by the channel.
  confirmed,

  /// Paid in advance.
  paid,

  /// The guest is staying now.
  staying,

  /// The stay is over.
  completed,
  cancelled,
}

/// One booking of a property, as listed on the property's «Брони» tab.
final class PropertyBookingEntity extends Equatable {
  const PropertyBookingEntity({
    required this.id,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.status,
    required this.totalPrice,
    required this.hasContract,
    this.channel,
  });

  /// Opens `AppRoutes.booking`; matches the calendar and property mocks.
  final String id;
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;

  /// The platform the booking came from; `null` for a direct booking.
  final BookingChannel? channel;
  final PropertyBookingStatus status;

  /// The price of the whole stay in whole tenge.
  final int totalPrice;

  /// Whether a rental contract was created («Договор не создан» if not).
  final bool hasContract;

  bool get isDirect => channel == null;

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
    id,
    guestName,
    checkIn,
    checkOut,
    guestCount,
    channel,
    status,
    totalPrice,
    hasContract,
  ];
}
