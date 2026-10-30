import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:easy_booking/core/utils/network/api_config.dart';

/// Builds the shared [Dio] with base URL, timeouts, and [interceptors].
///
/// The logger is appended last and added only when
/// [ApiConfig.enableLogging] is set. It logs method, URL, status, and
/// errors, but no headers or bodies: they carry tokens, phone numbers, SMS
/// codes, and guest documents.
Dio createDio({
  required ApiConfig config,
  List<Interceptor> interceptors = const <Interceptor>[],
}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  dio.interceptors.addAll(interceptors);
  if (config.enableLogging) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
      ),
    );
  }
  return dio;
}
