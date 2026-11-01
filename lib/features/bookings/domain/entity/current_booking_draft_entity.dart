import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';

/// What the source holds for a new booking: the saved [draft], if any, and
/// the source's [today], so step 1 can offer default dates without reading
/// the device clock.
final class CurrentBookingDraftEntity extends Equatable {
  const CurrentBookingDraftEntity({required this.today, this.draft});

  /// The saved draft; `null` when there is none.
  final BookingDraftEntity? draft;

  /// The source's current day, at midnight: the reference for the default
  /// dates and the earliest check-in of step 1.
  final DateTime today;

  @override
  List<Object?> get props => <Object?>[draft, today];
}
