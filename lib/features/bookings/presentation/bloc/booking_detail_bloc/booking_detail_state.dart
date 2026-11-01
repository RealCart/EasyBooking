part of 'booking_detail_bloc.dart';

final class BookingDetailState extends Equatable {
  const BookingDetailState({
    this.bookingId = '',
    this.loadStatus = RequestStatus.initial,
    this.booking,
    this.loadFailure,
    this.cancelStatus = RequestStatus.initial,
    this.cancelFailure,
  });

  /// The requested booking, for retrying a failed load.
  final String bookingId;

  final RequestStatus loadStatus;

  /// The last loaded booking; kept while a reload runs or after it fails.
  final BookingEntity? booking;

  /// Set when [loadStatus] is [RequestStatus.failure].
  final Failure? loadFailure;

  final RequestStatus cancelStatus;

  /// The failure of the last cancel, for a one-off message. Cleared when the
  /// next cancel starts.
  final Failure? cancelFailure;

  /// Whether the «Отменить бронь» action is available.
  bool get canCancel {
    return (booking?.status.isCancellable ?? false) && !cancelStatus.isLoading;
  }

  BookingDetailState copyWith({
    String? bookingId,
    RequestStatus? loadStatus,
    BookingEntity? booking,
    Failure? loadFailure,
    bool resetLoadFailure = false,
    RequestStatus? cancelStatus,
    Failure? cancelFailure,
    bool resetCancelFailure = false,
  }) {
    return BookingDetailState(
      bookingId: bookingId ?? this.bookingId,
      loadStatus: loadStatus ?? this.loadStatus,
      booking: booking ?? this.booking,
      loadFailure: resetLoadFailure ? null : loadFailure ?? this.loadFailure,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancelFailure: resetCancelFailure
          ? null
          : cancelFailure ?? this.cancelFailure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    bookingId,
    loadStatus,
    booking,
    loadFailure,
    cancelStatus,
    cancelFailure,
  ];
}
