import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('get forwards every argument and returns the response', () async {
    final CancelToken cancelToken = CancelToken();
    adapter.respond(200, <String, Object?>{'id': 1});

    final Response<Map<String, Object?>> response = await client
        .get<Map<String, Object?>>(
          '/items',
          data: body,
          queryParameters: query,
          options: options(),
          cancelToken: cancelToken,
          onReceiveProgress: onReceive,
        );

    expect(response.data, <String, Object?>{'id': 1});
    expectForwarded(
      adapter.requests.single,
      method: 'GET',
      cancelToken: cancelToken,
      hasSendProgress: false,
    );
  });

  test('post forwards every argument', () async {
    final CancelToken cancelToken = CancelToken();

    await client.post<Object?>(
      '/items',
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

    await client.put<Object?>(
      '/items',
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

    await client.patch<Object?>(
      '/items',
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

    await client.delete<Object?>(
      '/items',
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

  test('error statuses surface as DioException badResponse', () async {
    adapter.respond(500);

    await expectLater(
      client.get<Object?>('/items'),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.type,
          'type',
          DioExceptionType.badResponse,
        ),
      ),
    );
  });

  test('a cancelled token surfaces as DioException cancel', () async {
    final CancelToken cancelToken = CancelToken()..cancel('obsolete');

    await expectLater(
      client.get<Object?>('/items', cancelToken: cancelToken),
      throwsA(
        isA<DioException>().having(
          (DioException e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
  });

  test('close releases the Dio adapter', () {
    expect(adapter.isClosed, isFalse);

    client.close();

    expect(adapter.isClosed, isTrue);
  });
}
