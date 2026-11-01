import 'package:equatable/equatable.dart';

final class CancelBookingParamsEntity extends Equatable {
  const CancelBookingParamsEntity({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => <Object?>[bookingId];
}
