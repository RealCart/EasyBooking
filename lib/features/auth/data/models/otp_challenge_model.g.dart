// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpChallengeModel _$OtpChallengeModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OtpChallengeModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['resendAfterSeconds']);
      final val = OtpChallengeModel(
        resendAfterSeconds: $checkedConvert(
          'resendAfterSeconds',
          (v) => _nonNegativeInt(v),
        ),
      );
      return val;
    });
