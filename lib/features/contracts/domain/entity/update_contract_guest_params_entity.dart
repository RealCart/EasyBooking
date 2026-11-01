import 'package:equatable/equatable.dart';

/// The guest data confirmed on «Проверим данные гостя».
final class UpdateContractGuestParamsEntity extends Equatable {
  const UpdateContractGuestParamsEntity({
    required this.contractId,
    required this.firstName,
    required this.lastName,
    required this.patronymic,
    required this.iin,
    required this.idNumber,
  });

  final String contractId;
  final String firstName;
  final String lastName;

  /// Empty when the guest has no patronymic.
  final String patronymic;
  final String iin;
  final String idNumber;

  @override
  List<Object?> get props => <Object?>[
    contractId,
    firstName,
    lastName,
    patronymic,
    iin,
    idNumber,
  ];
}
