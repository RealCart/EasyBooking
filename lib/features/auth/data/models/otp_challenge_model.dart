import 'package:json_annotation/json_annotation.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';

part 'otp_challenge_model.g.dart';

/// Response of `POST /auth/otp/send`.
///
/// `fromJson` throws `CheckedFromJsonException` when `resendAfterSeconds`
/// is missing, not an int, or negative.
@JsonSerializable(checked: true, createToJson: false)
final class OtpChallengeModel {
  const OtpChallengeModel({required this.resendAfterSeconds});

  factory OtpChallengeModel.fromJson(Map<String, dynamic> json) =>
      _$OtpChallengeModelFromJson(json);

  @JsonKey(required: true, fromJson: _nonNegativeInt)
  final int resendAfterSeconds;

  /// The response does not echo the number, so the caller passes the one the
  /// code was sent to.
  OtpChallengeEntity toEntity({required String phone}) {
    return OtpChallengeEntity(
      phone: phone,
      resendAfter: Duration(seconds: resendAfterSeconds),
    );
  }
}

int _nonNegativeInt(Object? value) {
  if (value is! int || value < 0) {
    throw const ParsingException('must be a non-negative int');
  }
  return value;
}
