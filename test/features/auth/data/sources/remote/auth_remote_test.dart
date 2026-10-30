import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/auth_interceptor.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/features/auth/data/models/create_account_request_model.dart';
import 'package:easy_booking/features/auth/data/models/otp_challenge_model.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';

import '../../../../../helpers/fake_http_client_adapter.dart';
import '../../../../../helpers/fake_session_storage.dart';

const String _phone = '+77001234567';

const CreateAccountRequestModel _request = CreateAccountRequestModel(
  firstName: 'Айгерим',
  lastName: 'Садыкова',
  email: 'aigerim@example.kz',
  teamName: 'Esentai Stay',
  cityId: 'almaty',
  timeZone: 'Asia/Almaty',
);

void main() {
  late FakeHttpClientAdapter adapter;
  late AuthSession session;
  late Dio dio;
  late AuthRemote remote;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    session = AuthSession(sessionStorage: FakeSessionStorage());
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(session: session));
    remote = AuthRemoteImpl(apiClient: ApiClientImpl(dio: dio));
  });

  tearDown(() {
    dio.close(force: true);
    session.dispose();
  });

  RequestOptions lastRequest() => adapter.requests.single;

  group('AuthRemoteImpl.sendCode', () {
    test('posts the phone to /auth/otp/send and parses the delay', () async {
      adapter.respond(200, <String, Object?>{'resendAfterSeconds': 45});

      final OtpChallengeModel model = await remote.sendCode(_phone);

      expect(model.resendAfterSeconds, 45);
      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/auth/otp/send');
      expect(lastRequest().data, <String, Object?>{'phone': _phone});
    });

    test('skips auth so no bearer token is sent', () async {
      await session.signIn(const AuthTokens(accessToken: 'stale'));
      adapter.respond(200, <String, Object?>{'resendAfterSeconds': 30});

      await remote.sendCode(_phone);

      expect(lastRequest().extra[AuthInterceptor.skipAuthKey], isTrue);
      expect(lastRequest().headers, isNot(contains('Authorization')));
    });

    test('an invalid object body throws ParsingException', () async {
      adapter.respond(200, <String, Object?>{'resendAfterSeconds': -1});

      await expectLater(
        remote.sendCode(_phone),
        throwsA(isA<ParsingException>()),
      );
    });

    test('an error status surfaces as a DioException', () async {
      adapter.respond(422, <String, Object?>{'code': 'invalid_phone'});

      await expectLater(
        remote.sendCode(_phone),
        throwsA(
          isA<DioException>().having(
            (DioException e) => e.response?.statusCode,
            'statusCode',
            422,
          ),
        ),
      );
    });
  });

  group('AuthRemoteImpl.verifyCode', () {
    test('posts phone and code and parses the response', () async {
      adapter.respond(200, <String, Object?>{
        'accessToken': 'access',
        'refreshToken': null,
        'isNewUser': true,
      });

      final VerifyCodeResponseModel model = await remote.verifyCode(
        phone: _phone,
        code: '482913',
      );

      expect(model.accessToken, 'access');
      expect(model.refreshToken, isNull);
      expect(model.isNewUser, isTrue);
      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/auth/otp/verify');
      expect(lastRequest().data, <String, Object?>{
        'phone': _phone,
        'code': '482913',
      });
    });

    test('skips auth so no bearer token is sent', () async {
      await session.signIn(const AuthTokens(accessToken: 'stale'));
      adapter.respond(200, <String, Object?>{
        'accessToken': 'access',
        'isNewUser': false,
      });

      await remote.verifyCode(phone: _phone, code: '482913');

      expect(lastRequest().extra[AuthInterceptor.skipAuthKey], isTrue);
      expect(lastRequest().headers, isNot(contains('Authorization')));
    });

    test('a 401 for a skipped request does not close the session', () async {
      await session.signIn(const AuthTokens(accessToken: 'current'));
      adapter.respond(401, <String, Object?>{'code': 'invalid_code'});

      await expectLater(
        remote.verifyCode(phone: _phone, code: '000000'),
        throwsA(isA<DioException>()),
      );

      expect(session.isAuthenticated, isTrue);
    });

    test('an invalid object body throws ParsingException', () async {
      adapter.respond(200, <String, Object?>{'accessToken': ''});

      await expectLater(
        remote.verifyCode(phone: _phone, code: '482913'),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('AuthRemoteImpl.createAccount', () {
    test('posts the request JSON to /auth/account with auth', () async {
      await session.signIn(const AuthTokens(accessToken: 'access'));
      adapter.respond(201, <String, Object?>{'ignored': true});

      await remote.createAccount(_request);

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/auth/account');
      expect(lastRequest().data, _request.toJson());
      expect(lastRequest().extra, isNot(contains(AuthInterceptor.skipAuthKey)));
      expect(lastRequest().headers['Authorization'], 'Bearer access');
    });

    test('ignores any response body', () async {
      for (final Object? body in <Object?>[
        null,
        'created',
        <int>[1],
      ]) {
        adapter.respond(201, body);

        await expectLater(remote.createAccount(_request), completes);
      }
    });

    test('a 422 surfaces as a DioException', () async {
      adapter.respond(422, <String, Object?>{
        'errors': <String, Object?>{'email': 'taken'},
      });

      await expectLater(
        remote.createAccount(_request),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthRemoteImpl response shape', () {
    for (final (String name, Object? body) in <(String, Object?)>[
      ('null', null),
      ('a list', <Object?>[1, 2]),
      ('a string', 'ok'),
      ('a number', 42),
    ]) {
      test('a body that is $name throws ParsingException', () async {
        adapter.respond(200, body);

        await expectLater(
          remote.sendCode(_phone),
          throwsA(isA<ParsingException>()),
        );
        await expectLater(
          remote.verifyCode(phone: _phone, code: '482913'),
          throwsA(isA<ParsingException>()),
        );
      });
    }
  });
}
