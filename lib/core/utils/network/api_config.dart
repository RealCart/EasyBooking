import 'package:flutter/foundation.dart';

final class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.sendTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
    this.enableLogging = false,
  });

  /// Reads the base URL from `--dart-define=API_BASE_URL=https://...`.
  ///
  /// Request and response bodies are logged in debug builds only.
  factory ApiConfig.fromEnvironment() {
    return const ApiConfig(
      baseUrl: String.fromEnvironment('API_BASE_URL'),
      enableLogging: kDebugMode,
    );
  }

  final String baseUrl;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;
}
