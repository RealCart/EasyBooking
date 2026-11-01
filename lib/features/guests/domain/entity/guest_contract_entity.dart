import 'package:equatable/equatable.dart';

/// The state of a rental contract sent to a guest.
enum GuestContractStatus {
  /// Sent, not opened yet («Ждём подпись»).
  sent,

  /// Opened by the guest, not signed yet («Ждём подпись»).
  opened,

  signed;

  bool get isAwaitingSignature => this != GuestContractStatus.signed;
}

/// A rental contract of a guest for one stay.
final class GuestContractEntity extends Equatable {
  const GuestContractEntity({
    required this.id,
    required this.number,
    required this.guestId,
    required this.guestName,
    required this.bookingId,
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.status,
    required this.updatedAt,
  });

  /// Opens `AppRoutes.contract`.
  final String id;

  /// The number printed on the contract, such as `EB-1048`.
  final String number;

  /// Opens `AppRoutes.guest`.
  final String guestId;
  final String guestName;

  /// The stay the contract covers; opens `AppRoutes.booking`.
  final String bookingId;
  final String propertyId;
  final String propertyName;
  final String unit;
  final GuestContractStatus status;

  /// When [status] was reached: sent, opened, or signed.
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    number,
    guestId,
    guestName,
    bookingId,
    propertyId,
    propertyName,
    unit,
    status,
    updatedAt,
  ];
}
