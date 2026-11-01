import 'package:equatable/equatable.dart';

/// Whether the dates of a draft are free in every calendar of the property.
final class BookingAvailabilityEntity extends Equatable {
  const BookingAvailabilityEntity({
    required this.checkedChannelNames,
    this.conflictingBookingIds = const <String>[],
  });

  /// Channels whose calendars were checked besides the local one, such as
  /// `Airbnb`, `Booking.com`.
  final List<String> checkedChannelNames;

  /// Bookings that overlap the dates; empty when the dates are free.
  final List<String> conflictingBookingIds;

  bool get isAvailable => conflictingBookingIds.isEmpty;

  @override
  List<Object?> get props => <Object?>[
    checkedChannelNames,
    conflictingBookingIds,
  ];
}
