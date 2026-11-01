import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_availability_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';

/// Step 1 of a new booking («Когда и где»), saved by the source together
/// with its quote, so step 2 («Цена и источник») can read it.
final class BookingDraftEntity extends Equatable {
  const BookingDraftEntity({
    required this.id,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.checkIn,
    required this.checkOut,
    required this.guest,
    required this.suggestedTotalPrice,
    required this.suggestedDeposit,
    required this.availability,
  });

  /// Passed back in `CreateBookingParamsEntity.draftId`.
  final String id;
  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName], such as `84`.
  final String unit;
  final DateTime checkIn;
  final DateTime checkOut;
  final BookingGuestEntity guest;

  /// Nights × the property's base price, in whole tenge; the starting value
  /// of «Итого».
  final int suggestedTotalPrice;

  /// The starting value of «Депозит», in whole tenge.
  final int suggestedDeposit;
  final BookingAvailabilityEntity availability;

  int get nights => checkIn.nightsUntil(checkOut);

  @override
  List<Object?> get props => <Object?>[
    id,
    propertyId,
    propertyName,
    unit,
    checkIn,
    checkOut,
    guest,
    suggestedTotalPrice,
    suggestedDeposit,
    availability,
  ];
}
