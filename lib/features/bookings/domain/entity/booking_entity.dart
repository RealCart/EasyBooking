import 'package:equatable/equatable.dart';

import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_contract_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';

enum BookingStatus {
  /// Check-in is still ahead; booked, but neither confirmed by a channel nor
  /// paid yet, as a booking added by hand («Напрямую»).
  pending,

  /// Check-in is still ahead; confirmed by the channel or the host.
  confirmed,

  /// The guest is living in the apartment.
  checkedIn,

  /// The guest has checked out.
  completed,
  cancelled;

  /// Whether the host can still cancel it.
  bool get isCancellable {
    return this == BookingStatus.pending ||
        this == BookingStatus.confirmed ||
        this == BookingStatus.checkedIn;
  }
}

/// Where the booking came from.
enum BookingSource {
  airbnb,
  bookingCom,
  krisha,
  direct,
  other;

  /// The sources a host can pick for a booking added by hand («Напрямую»,
  /// «Krisha», «Другое»); the channels import their own bookings.
  static const List<BookingSource> manual = <BookingSource>[
    BookingSource.direct,
    BookingSource.krisha,
    BookingSource.other,
  ];

  bool get isManual => manual.contains(this);
}

/// A stay of a guest in one of the host's apartments.
final class BookingEntity extends Equatable {
  const BookingEntity({
    required this.id,
    required this.status,
    required this.source,
    required this.guest,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.deposit,
    required this.isDepositPaid,
    required this.isPaid,
    required this.receivedAt,
    this.externalCode,
    this.guestCount,
    this.comment,
    this.contract,
  });

  final String id;
  final BookingStatus status;
  final BookingSource source;

  /// The channel's confirmation code, such as `HM73P2`; `null` for a booking
  /// added by hand.
  final String? externalCode;
  final BookingGuestEntity guest;

  /// Number of guests; `null` when the host did not specify it.
  final int? guestCount;
  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName], such as `84`.
  final String unit;
  final DateTime checkIn;
  final DateTime checkOut;

  /// Price of the whole stay in whole tenge.
  final int totalPrice;

  /// Security deposit in whole tenge; `0` when none is taken.
  final int deposit;
  final bool isDepositPaid;

  /// Whether [totalPrice] was paid in advance («Оплачено»).
  final bool isPaid;

  /// A note for the team.
  final String? comment;

  /// `null` when no contract was created for the booking.
  final BookingContractEntity? contract;

  /// The source's current time when it answered: the reference for
  /// relative labels («Отправлен сегодня, 10:12»).
  final DateTime receivedAt;

  int get nights => checkIn.nightsUntil(checkOut);

  @override
  List<Object?> get props => <Object?>[
    id,
    status,
    source,
    externalCode,
    guest,
    guestCount,
    propertyId,
    propertyName,
    unit,
    checkIn,
    checkOut,
    totalPrice,
    deposit,
    isDepositPaid,
    isPaid,
    comment,
    contract,
    receivedAt,
  ];
}
