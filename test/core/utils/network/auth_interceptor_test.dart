import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/network/interceptors/auth_interceptor.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';

import '../../../helpers/fake_http_client_adapter.dart';
import '../../../helpers/fake_session_storage.dart';

const AuthTokens _firstTokens = AuthTokens(accessToken: 'first');
const AuthTokens _secondTokens = AuthTokens(accessToken: 'second');

void main() {
  late FakeSessionStorage storage;
  late AuthSession session;
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    storage = FakeSessionStorage();
    session = AuthSession(sessionStorage: storage);
    adapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(session: session));
  });

  tearDown(() {
    dio.close(force: true);
    session.dispose();
  });

  String? authorizationOf(RequestOptions options) {
    return options.headers['Authorization'] as String?;
  }

  group('AuthInterceptor.onRequest', () {
    test('adds the bearer token when signed in', () async {
      await session.signIn(_firstTokens);

      await dio.get<Object?>('/items');

      expect(authorizationOf(adapter.requests.single), 'Bearer first');
    });

    test('adds no header when signed out', () async {
      await dio.get<Object?>('/items');

      expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    });

    test('adds no header when the request opts out with skipAuth', () async {
      await session.signIn(_firstTokens);

      await dio.post<Object?>(
        '/auth/code',
        options: Options(
          extra: <String, Object?>{AuthInterceptor.skipAuthKey: true},
        ),
      );

      expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    });

    test('a non-true skipAuth value still adds the header', () async {
      await session.signIn(_firstTokens);

      await dio.get<Object?>(
        '/items',
        options: Options(
          extra: <String, Object?>{AuthInterceptor.skipAuthKey: 'true'},
        ),
      );

      expect(authorizationOf(adapter.requests.single), 'Bearer first');
    });

    test('uses the token current at send time', () async {
      await session.signIn(_firstTokens);
      await dio.get<Object?>('/a');
      await session.signIn(_secondTokens);
      await dio.get<Object?>('/b');

      expect(adapter.requests.map(authorizationOf), <String?>[
        'Bearer first',
        'Bearer second',
      ]);
    });
  });

  group('AuthInterceptor.onError', () {
    test('401 for the current token signs out and rethrows', () async {
      await session.signIn(_firstTokens);
      adapter.respond(401);

      await expectLater(
        dio.get<Object?>('/items'),
        throwsA(
          isA<DioException>().having(
            (DioException e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );

      expect(session.isAuthenticated, isFalse);
      expect(storage.clearCount, 1);
    });

    test('401 still signs out in memory when clearing storage fails', () async {
      await session.signIn(_firstTokens);
      storage.failClears = true;
      adapter.respond(401);

      await expectLater(
        dio.get<Object?>('/items'),
        throwsA(isA<DioException>()),
      );

      expect(session.isAuthenticated, isFalse);
    });

    test('stale 401 sent with an older token keeps the new session', () async {
      await session.signIn(_firstTokens);
      adapter.hold();
      final Future<Response<Object?>> staleRequest = dio.get<Object?>('/old');
      await pumpEventQueue();
      expect(authorizationOf(adapter.requests.single), 'Bearer first');

      await session.signOut();
      await session.signIn(_secondTokens);
      adapter.release(0, 401);

      await expectLater(staleRequest, throwsA(isA<DioException>()));
      expect(session.tokens, _secondTokens);
      expect(storage.storedTokens, _secondTokens);
    });

    test('401 for a skipAuth request does not sign out', () async {
      await session.signIn(_firstTokens);
      adapter.respond(401);

      await expectLater(
        dio.post<Object?>(
          '/auth/verify',
          options: Options(
            extra: <String, Object?>{AuthInterceptor.skipAuthKey: true},
          ),
        ),
        throwsA(isA<DioException>()),
      );

      expect(session.isAuthenticated, isTrue);
      expect(storage.clearCount, 0);
    });

    test('401 while signed out does not touch storage', () async {
      adapter.respond(401);

      await expectLater(
        dio.get<Object?>('/items'),
        throwsA(isA<DioException>()),
      );

      expect(storage.clearCount, 0);
    });

    test('other error statuses keep the session', () async {
      await session.signIn(_firstTokens);

      for (final int status in <int>[400, 403, 500]) {
        adapter.respond(status);
        await expectLater(
          dio.get<Object?>('/items'),
          throwsA(isA<DioException>()),
        );
      }

      expect(session.isAuthenticated, isTrue);
      expect(storage.clearCount, 0);
    });
  });
}
