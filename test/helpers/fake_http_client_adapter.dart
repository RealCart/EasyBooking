import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers requests without a network and records the final options.
///
/// By default every request gets `200 {}`. Use [respond] to choose a status,
/// or [hold] to keep the next request pending until the test completes it.
final class FakeHttpClientAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  int statusCode = 200;
  Object? body = const <String, Object?>{};

  final List<Completer<ResponseBody>> _held = <Completer<ResponseBody>>[];
  int _holdNext = 0;

  void respond(int statusCode, [Object? body = const <String, Object?>{}]) {
    this.statusCode = statusCode;
    this.body = body;
  }

  /// Keeps the next request pending. Complete it with [release].
  void hold() => _holdNext++;

  /// Completes the held request at [index] with [statusCode].
  void release(int index, int statusCode) {
    _held[index].complete(_response(statusCode, const <String, Object?>{}));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      await requestStream.drain<void>();
    }
    if (_holdNext > 0) {
      _holdNext--;
      final Completer<ResponseBody> completer = Completer<ResponseBody>();
      _held.add(completer);
      return completer.future;
    }
    return _response(statusCode, body);
  }

  ResponseBody _response(int status, Object? data) {
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  bool isClosed = false;

  @override
  void close({bool force = false}) => isClosed = true;
}
