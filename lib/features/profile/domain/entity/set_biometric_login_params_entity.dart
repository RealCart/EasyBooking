import 'package:equatable/equatable.dart';

final class SetBiometricLoginParamsEntity extends Equatable {
  const SetBiometricLoginParamsEntity({required this.isEnabled});

  final bool isEnabled;

  @override
  List<Object?> get props => <Object?>[isEnabled];
}
