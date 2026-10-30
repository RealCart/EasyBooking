import 'package:equatable/equatable.dart';

/// An SMS code that was sent to [phone].
final class OtpChallengeEntity extends Equatable {
  const OtpChallengeEntity({required this.phone, required this.resendAfter});

  /// The number the code was sent to, in E.164 format (`+77001234567`).
  final String phone;

  /// How long to wait before a new code may be requested.
  final Duration resendAfter;

  @override
  List<Object?> get props => <Object?>[phone, resendAfter];
}
