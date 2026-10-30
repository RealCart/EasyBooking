import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';

const Map<String, Object?> _valid = <String, Object?>{
  'accessToken': 'secret-access',
  'refreshToken': 'secret-refresh',
  'isNewUser': true,
};

void main() {
  group('VerifyCodeResponseModel.fromJson', () {
    test('reads both tokens and isNewUser', () {
      final VerifyCodeResponseModel model = VerifyCodeResponseModel.fromJson(
        _valid,
      );

      expect(model.accessToken, 'secret-access');
      expect(model.refreshToken, 'secret-refresh');
      expect(model.isNewUser, isTrue);
    });

    test('accepts a null or missing refresh token', () {
      for (final Map<String, Object?> json in <Map<String, Object?>>[
        <String, Object?>{..._valid, 'refreshToken': null},
        <String, Object?>{..._valid}..remove('refreshToken'),
      ]) {
        expect(VerifyCodeResponseModel.fromJson(json).refreshToken, isNull);
      }
    });

    test('reads isNewUser false', () {
      expect(
        VerifyCodeResponseModel.fromJson(<String, Object?>{
          ..._valid,
          'isNewUser': false,
        }).isNewUser,
        isFalse,
      );
    });

    test('throws ParsingException for an invalid access token', () {
      for (final Object? accessToken in <Object?>[null, '', 42, true]) {
        expect(
          () => VerifyCodeResponseModel.fromJson(<String, Object?>{
            ..._valid,
            'accessToken': accessToken,
          }),
          throwsA(isA<ParsingException>()),
          reason: '$accessToken',
        );
      }
      expect(
        () => VerifyCodeResponseModel.fromJson(
          <String, Object?>{..._valid}..remove('accessToken'),
        ),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException for a non-string refresh token', () {
      for (final Object refreshToken in <Object>[42, false, <String>[]]) {
        expect(
          () => VerifyCodeResponseModel.fromJson(<String, Object?>{
            ..._valid,
            'refreshToken': refreshToken,
          }),
          throwsA(isA<ParsingException>()),
          reason: '$refreshToken',
        );
      }
    });

    test('throws ParsingException for a missing or non-bool isNewUser', () {
      for (final Object? isNewUser in <Object?>[null, 'true', 1]) {
        expect(
          () => VerifyCodeResponseModel.fromJson(<String, Object?>{
            ..._valid,
            'isNewUser': isNewUser,
          }),
          throwsA(isA<ParsingException>()),
          reason: '$isNewUser',
        );
      }
      expect(
        () => VerifyCodeResponseModel.fromJson(
          <String, Object?>{..._valid}..remove('isNewUser'),
        ),
        throwsA(isA<ParsingException>()),
      );
    });

    test('parsing errors never include token values', () {
      for (final Map<String, Object?> json in <Map<String, Object?>>[
        <String, Object?>{..._valid, 'refreshToken': 42},
        <String, Object?>{..._valid, 'isNewUser': 'secret-flag'},
      ]) {
        try {
          VerifyCodeResponseModel.fromJson(json);
          fail('Expected a ParsingException for $json');
        } on ParsingException catch (exception) {
          expect(exception.toString(), isNot(contains('secret')));
        }
      }
    });
  });

  group('VerifyCodeResponseModel', () {
    test('toTokens maps both tokens', () {
      expect(
        VerifyCodeResponseModel.fromJson(_valid).toTokens(),
        const AuthTokens(
          accessToken: 'secret-access',
          refreshToken: 'secret-refresh',
        ),
      );
    });

    test('toTokens keeps a missing refresh token null', () {
      expect(
        const VerifyCodeResponseModel(
          accessToken: 'access',
          isNewUser: false,
        ).toTokens(),
        const AuthTokens(accessToken: 'access'),
      );
    });

    test('toString redacts the tokens', () {
      final String text = VerifyCodeResponseModel.fromJson(_valid).toString();

      expect(text, isNot(contains('secret')));
      expect(text, contains('isNewUser: true'));
    });
  });
}
