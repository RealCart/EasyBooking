import 'package:equatable/equatable.dart';

enum BookingContractStatus {
  /// Created with the booking, not sent to the guest yet.
  draft,

  /// Sent to the guest, not signed yet.
  awaitingSignature,
  signed,
}

/// The rental contract of a booking.
final class BookingContractEntity extends Equatable {
  const BookingContractEntity({
    required this.status,
    this.id,
    this.sentAt,
    this.signedAt,
  });

  /// The contract to open on the contract screen; `null` while the contract
  /// is not available in the app yet (it cannot be opened).
  final String? id;
  final BookingContractStatus status;

  /// When it was sent to the guest; `null` for a [BookingContractStatus.draft].
  final DateTime? sentAt;

  /// Set only when [status] is [BookingContractStatus.signed].
  final DateTime? signedAt;

  @override
  List<Object?> get props => <Object?>[id, status, sentAt, signedAt];
}
