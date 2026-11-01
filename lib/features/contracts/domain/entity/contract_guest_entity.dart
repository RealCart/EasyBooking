import 'package:equatable/equatable.dart';

/// The guest who signs the contract, as recognized from the identity
/// document and confirmed by the host.
final class ContractGuestEntity extends Equatable {
  const ContractGuestEntity({
    required this.firstName,
    required this.lastName,
    required this.iin,
    required this.idNumber,
    required this.phone,
    this.patronymic,
  });

  final String firstName;
  final String lastName;

  /// `null` when the guest has no patronymic.
  final String? patronymic;

  /// Individual identification number, twelve digits.
  final String iin;

  /// Identity card number, nine digits.
  final String idNumber;

  /// The signing contact in E.164 format (`+77005124521`).
  final String phone;

  /// «Данияр Муратов».
  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    patronymic,
    iin,
    idNumber,
    phone,
  ];
}
