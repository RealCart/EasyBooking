import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

/// The chips above the booking list: «Предстоящие» and «Прошедшие».
enum PropertyBookingsPeriod { upcoming, past }

/// The bookings of one property, split by the source relative to now.
final class PropertyBookingsEntity extends Equatable {
  const PropertyBookingsEntity({
    required this.property,
    required this.upcoming,
    required this.past,
    required this.receivedAt,
  });

  /// For the header («Esentai City · 84»).
  final PropertyEntity property;

  /// Current and future stays, the earliest check-in first.
  final List<PropertyBookingEntity> upcoming;

  /// Finished and cancelled stays, the latest check-in first.
  final List<PropertyBookingEntity> past;

  /// The source's current time when it answered, which also split
  /// [upcoming] from [past]: the reference for labels relative to today
  /// («СЕГ», the year of a month header).
  final DateTime receivedAt;

  List<PropertyBookingEntity> bookingsFor(PropertyBookingsPeriod period) {
    return switch (period) {
      PropertyBookingsPeriod.upcoming => upcoming,
      PropertyBookingsPeriod.past => past,
    };
  }

  @override
  List<Object?> get props => <Object?>[property, upcoming, past, receivedAt];
}
