import 'package:equatable/equatable.dart';

/// Input of `VerifyCodeUsecase`.
final class VerifyCodeParamsEntity extends Equatable {
  const VerifyCodeParamsEntity({required this.phone, required this.code});

  /// E.164 number the code was sent to.
  final String phone;

  final String code;

  @override
  List<Object?> get props => <Object?>[phone, code];
}
