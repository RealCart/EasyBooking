import 'package:equatable/equatable.dart';

final class CreateGuestContractParamsEntity extends Equatable {
  const CreateGuestContractParamsEntity({required this.guestId});

  final String guestId;

  @override
  List<Object?> get props => <Object?>[guestId];
}
