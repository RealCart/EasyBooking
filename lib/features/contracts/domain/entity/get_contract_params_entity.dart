import 'package:equatable/equatable.dart';

final class GetContractParamsEntity extends Equatable {
  const GetContractParamsEntity({required this.contractId});

  final String contractId;

  @override
  List<Object?> get props => <Object?>[contractId];
}
