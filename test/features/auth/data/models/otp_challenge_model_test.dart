import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';

void main() {
  group('OtpChallengeModel.fromJson', () {
    test('reads resendAfterSeconds', () {
      expect(
        OtpChallengeModel.fromJson(const <String, Object?>{
          'resendAfterSeconds': 30,
        }).resendAfterSeconds,
        30,
      );
    });

    test('accepts zero', () {
      expect(
        OtpChallengeModel.fromJson(const <String, Object?>{
          'resendAfterSeconds': 0,
        }).resendAfterSeconds,
        0,
      );
    });

    test('ignores unknown keys', () {
      expect(
        OtpChallengeModel.fromJson(const <String, Object?>{
          'resendAfterSeconds': 45,
          'extra': true,
        }).resendAfterSeconds,
        45,
      );
    });

    test('throws ParsingException for a missing or invalid value', () {
      for (final Map<String, Object?> json in <Map<String, Object?>>[
        const <String, Object?>{},
        const <String, Object?>{'resendAfterSeconds': null},
        const <String, Object?>{'resendAfterSeconds': -1},
        const <String, Object?>{'resendAfterSeconds': 30.5},
        const <String, Object?>{'resendAfterSeconds': '30'},
        const <String, Object?>{'resendAfterSeconds': true},
        const <String, Object?>{'resend_after_seconds': 30},
      ]) {
        expect(
          () => OtpChallengeModel.fromJson(json),
          throwsA(isA<ParsingException>()),
          reason: '$json',
        );
      }
    });
  });

  group('OtpChallengeModel.toEntity', () {
    test('uses the given phone and the delay as a Duration', () {
      expect(
        const OtpChallengeModel(
          resendAfterSeconds: 90,
        ).toEntity(phone: '+77001234567'),
        const OtpChallengeEntity(
          phone: '+77001234567',
          resendAfter: Duration(seconds: 90),
        ),
      );
    });
  });
}
