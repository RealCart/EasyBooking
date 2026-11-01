import 'package:equatable/equatable.dart';

final class GetBookingParamsEntity extends Equatable {
  const GetBookingParamsEntity({required this.bookingId});

  final String bookingId;

  @override
  List<Object?> get props => <Object?>[bookingId];
}
