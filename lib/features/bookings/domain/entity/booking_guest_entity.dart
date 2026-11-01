import 'package:equatable/equatable.dart';

/// The guest a booking is made for.
final class BookingGuestEntity extends Equatable {
  const BookingGuestEntity({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  final String firstName;

  /// Empty when the host has not entered it yet.
  final String lastName;

  /// E.164, such as `+77002454521`.
  final String phone;

  /// `Айжан Сарсенова`, or only the first name when [lastName] is empty.
  String get fullName {
    return lastName.isEmpty ? firstName : '$firstName $lastName';
  }

  @override
  List<Object?> get props => <Object?>[firstName, lastName, phone];
}
