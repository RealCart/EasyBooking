import 'package:equatable/equatable.dart';

/// Input of `SendCodeUsecase`.
final class SendCodeParamsEntity extends Equatable {
  const SendCodeParamsEntity({required this.phone});

  /// Phone number in any user-typed format; the use case normalizes it.
  final String phone;

  @override
  List<Object?> get props => <Object?>[phone];
}
