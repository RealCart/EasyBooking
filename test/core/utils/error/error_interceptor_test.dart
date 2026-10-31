import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/network/interceptors/error_interceptor.dart';
import 'package:easy_booking/core/utils/error/failure.dart';

import '../../../helpers/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(const ErrorInterceptor());
  });

  tearDown(() => dio.close(force: true));

  Future<DioException> failedRequest() async {
    try {
      await dio.get<Object?>('/items');
    } on DioException catch (exception) {
      return exception;
    }
    throw TestFailure('Expected the request to fail');
  }

  test('stores the mapped failure of an error status as the error', () async {
    adapter.respond(422, <String, Object?>{
      'code': 'invalid',
      'errors': <String, Object?>{'email': 'taken'},
    });

    final DioException exception = await failedRequest();

    expect(
      exception.error,
      const ValidationFailure(
        code: 'invalid',
        fieldErrors: <String, String>{'email': 'taken'},
      ),
    );
  });

  test('keeps the response and type of the original error', () async {
    adapter.respond(500);

    final DioException exception = await failedRequest();

    expect(exception.type, DioExceptionType.badResponse);
    expect(exception.response?.statusCode, 500);
    expect(exception.error, const ServerFailure(statusCode: 500));
  });

  test('passes a successful response through', () async {
    adapter.respond(200, <String, Object?>{'id': 1});

    final Response<Object?> response = await dio.get<Object?>('/items');

    expect(response.data, <String, Object?>{'id': 1});
  });
}
