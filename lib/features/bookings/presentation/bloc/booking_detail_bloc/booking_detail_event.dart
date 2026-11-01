part of 'booking_detail_bloc.dart';

sealed class BookingDetailEvent extends Equatable {
  const BookingDetailEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads [bookingId]: added when the BLoC is created and on retry.
final class BookingDetailRequested extends BookingDetailEvent {
  const BookingDetailRequested(this.bookingId);

  final String bookingId;

  @override
  List<Object?> get props => <Object?>[bookingId];
}

/// The host confirmed «Отменить бронь» for the loaded booking.
final class BookingDetailCancelRequested extends BookingDetailEvent {
  const BookingDetailCancelRequested();
}
