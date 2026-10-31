import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/network/interceptors/error_interceptor.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';

import '../../../helpers/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;
  late ApiClient client;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    client = ApiClientImpl(dio: dio);
  });

  tearDown(() => dio.close(force: true));

  void onSend(int sent, int total) {}
  void onReceive(int received, int total) {}

  final Map<String, Object?> body = <String, Object?>{'name': 'Flat'};
  final Map<String, Object?> query = <String, Object?>{'page': 2, 'q': 'a'};

  Options options() {
    return Options(
      headers: <String, Object?>{'X-Trace': 'trace-1'},
      extra: <String, Object?>{'marker': 'm'},
      responseType: ResponseType.json,
    );
  }

  void expectForwarded(
    RequestOptions request, {
    required String method,
    required CancelToken cancelToken,
    bool hasSendProgress = true,
    bool hasReceiveProgress = true,
  }) {
    expect(request.method, method);
    expect(request.uri.toString(), 'https://api.test/items?page=2&q=a');
    expect(request.data, body);
    expect(request.queryParameters, query);
    expect(request.headers['X-Trace'], 'trace-1');
    expect(request.extra['marker'], 'm');
    expect(request.cancelToken, same(cancelToken));
    expect(
      request.onSendProgress,
      hasSendProgress ? same(onSend) : isNull,
    );
    expect(
      request.onReceiveProgress,
      hasReceiveProgress ? same(onReceive) : isNull,
    );
  }

  Object? keepBody(Object? data) => data;

  test('get forwards every argument and returns the parsed body', () async {
    final CancelToken cancelToken = CancelToken();
    adapter.respond(200, <String, Object?>{'id': 1});

    final Either<Failure, Object?> result = await client.get(
      '/items',
      parse: keepBody,
      data: body,
      queryParameters: query,
      options: options(),
      cancelToken: cancelToken,
      onReceiveProgress: onReceive,
    );

    expect(
      result,
      const Right<Failure, Object?>(<String, Object?>{'id': 1}),
    );
    expectForwarded(
      adapter.requests.single,
      method: 'GET',
      cancelToken: cancelToken,
      hasSendProgress: false,
    );
  });

  test('post forwards every argument', () async {
    final CancelToken cancelToken = CancelToken();

    await client.post(
      '/items',
      parse: keepBody,
      data: body,
      queryParameters: query,
      options: options(),
      cancelToken: cancelToken,
      onSendProgress: onSend,
      onReceiveProgress: onReceive,
    );

    expectForwarded(
      adapter.requests.single,
      method: 'POST',
      cancelToken: cancelToken,
    );
  });

  test('put forwards every argument', () async {
    final CancelToken cancelToken = CancelToken();

    await client.put(
      '/items',
      parse: keepBody,
      data: body,
      queryParameters: query,
      options: options(),
      cancelToken: cancelToken,
      onSendProgress: onSend,
      onReceiveProgress: onReceive,
    );

    expectForwarded(
      adapter.requests.single,
      method: 'PUT',
      cancelToken: cancelToken,
    );
  });

  test('patch forwards every argument', () async {
    final CancelToken cancelToken = CancelToken();

    await client.patch(
      '/items',
      parse: keepBody,
      data: body,
      queryParameters: query,
      options: options(),
      cancelToken: cancelToken,
      onSendProgress: onSend,
      onReceiveProgress: onReceive,
    );

    expectForwarded(
      adapter.requests.single,
      method: 'PATCH',
      cancelToken: cancelToken,
    );
  });

  test('delete forwards every argument', () async {
    final CancelToken cancelToken = CancelToken();

    await client.delete(
      '/items',
      parse: keepBody,
      data: body,
      queryParameters: query,
      options: options(),
      cancelToken: cancelToken,
    );

    expectForwarded(
      adapter.requests.single,
      method: 'DELETE',
      cancelToken: cancelToken,
      hasSendProgress: false,
      hasReceiveProgress: false,
    );
  });

  test('an error status is a Left with the mapped failure', () async {
    adapter.respond(500, <String, Object?>{'code': 'down'});

    expect(
      await client.get('/items', parse: keepBody),
      const Left<Failure, Object?>(
        ServerFailure(statusCode: 500, code: 'down'),
      ),
    );
  });

  test('a cancelled token is a Left CancelledFailure', () async {
    final CancelToken cancelToken = CancelToken()..cancel('obsolete');

    final Either<Failure, Object?> result = await client.get(
      '/items',
      parse: keepBody,
      cancelToken: cancelToken,
    );

    expect(result, isA<Left<Failure, Object?>>());
    expect((result as Left<Failure, Object?>).value, isA<CancelledFailure>());
    expect(adapter.requests, isEmpty);
  });

  test('returns the failure stored by ErrorInterceptor as is', () async {
    dio.interceptors.add(const ErrorInterceptor());
    adapter.respond(401, <String, Object?>{'message': 'expired'});

    expect(
      await client.get('/items', parse: keepBody),
      const Left<Failure, Object?>(UnauthorizedFailure(message: 'expired')),
    );
  });

  test('a parse exception is a Left ParsingFailure', () async {
    adapter.respond(200, <Object?>[1, 2]);

    expect(
      await client.get(
        '/items',
        parse: jsonObject((Map<String, dynamic> json) => json),
      ),
      const Left<Failure, Map<String, dynamic>>(
        ParsingFailure(message: 'Expected a JSON object, got List<dynamic>'),
      ),
    );
  });

  test('an Error thrown by the parser propagates', () async {
    adapter.respond(200, <String, Object?>{'id': 1});

    await expectLater(
      client.get<int>('/items', parse: (_) => throw StateError('bug')),
      throwsA(isA<StateError>()),
    );
  });

  test('jsonObject passes a JSON object to fromJson', () async {
    adapter.respond(200, <String, Object?>{'id': 7});

    expect(
      await client.get(
        '/items',
        parse: jsonObject<Object?>((Map<String, dynamic> json) => json['id']),
      ),
      const Right<Failure, Object?>(7),
    );
  });

  test('close releases the Dio adapter', () {
    expect(adapter.isClosed, isFalse);

    client.close();

    expect(adapter.isClosed, isTrue);
  });
}
