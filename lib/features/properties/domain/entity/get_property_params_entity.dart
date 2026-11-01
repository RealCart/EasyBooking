import 'package:equatable/equatable.dart';

final class GetPropertyParamsEntity extends Equatable {
  const GetPropertyParamsEntity({required this.propertyId});

  final String propertyId;

  @override
  List<Object?> get props => <Object?>[propertyId];
}
