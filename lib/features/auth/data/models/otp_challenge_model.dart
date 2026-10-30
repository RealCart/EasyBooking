import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';

/// Response of `POST /auth/otp/send`.
final class OtpChallengeModel {
  const OtpChallengeModel({required this.resendAfterSeconds});

  /// Throws [ParsingException] when `resendAfterSeconds` is not an int ≥ 0.
  factory OtpChallengeModel.fromJson(Map<String, Object?> json) {
    final Object? resendAfterSeconds = json[_resendAfterSecondsKey];
    if (resendAfterSeconds is! int || resendAfterSeconds < 0) {
      throw const ParsingException(
        'OtpChallenge: resendAfterSeconds must be a non-negative int',
      );
    }
    return OtpChallengeModel(resendAfterSeconds: resendAfterSeconds);
  }

  static const String _resendAfterSecondsKey = 'resendAfterSeconds';

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
