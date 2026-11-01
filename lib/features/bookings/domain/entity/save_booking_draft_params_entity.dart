import 'package:equatable/equatable.dart';

/// Input of `SaveBookingDraftUsecase`: the «Когда и где» form.
final class SaveBookingDraftParamsEntity extends Equatable {
  const SaveBookingDraftParamsEntity({
    required this.propertyId,
    required this.checkIn,
    required this.checkOut,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  final String propertyId;

  /// Date and time of arrival.
  final DateTime checkIn;

  /// Date and time of departure; at least one night after [checkIn].
  final DateTime checkOut;
  final String firstName;

  /// May be empty.
  final String lastName;

  /// As typed; the use case normalizes it to E.164.
  final String phone;

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    checkIn,
    checkOut,
    firstName,
    lastName,
    phone,
  ];
}
