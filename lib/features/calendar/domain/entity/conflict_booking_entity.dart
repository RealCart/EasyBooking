import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/calendar/domain/entity/booking_source.dart';

/// One of the overlapping bookings of a calendar conflict.
final class ConflictBookingEntity extends Equatable {
  const ConflictBookingEntity({
    required this.bookingId,
    required this.source,
    required this.guestName,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.createdAt,
    required this.isConfirmed,
    required this.isPhoneVerified,
    this.confirmationCode,
  });

  final String bookingId;
  final BookingSource source;

  /// First name, as shown in the list.
  final String guestName;
  final DateTime checkIn;
  final DateTime checkOut;

  /// Price of the whole stay in whole tenge.
  final int totalPrice;
  final DateTime createdAt;

  /// The channel confirmed the booking («Подтверждена»); otherwise it is
  /// only created («Создана вчера»).
  final bool isConfirmed;

  /// The guest's phone number was confirmed («телефон подтверждён»).
  final bool isPhoneVerified;

  /// The channel's reservation code, such as `HM73P2`.
  final String? confirmationCode;

  int get nights => checkIn.nightsUntil(checkOut);

  @override
  List<Object?> get props => <Object?>[
    bookingId,
    source,
    guestName,
    checkIn,
    checkOut,
    totalPrice,
    createdAt,
    isConfirmed,
    isPhoneVerified,
    confirmationCode,
  ];
}
