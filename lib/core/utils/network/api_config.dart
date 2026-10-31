import 'package:flutter/foundation.dart';

import 'package:easy_booking/core/utils/network/app_api.dart';

final class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });

  /// Uses [AppApi.baseUrl], set with `--dart-define=API_BASE_URL=...`.
  ///
  /// Request and response bodies are logged in debug builds only.
  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(
      baseUrl: AppApi.baseUrl,
      enableLogging: kDebugMode,
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
}
