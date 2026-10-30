import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Application logger backed by `dart:developer`.
///
/// Never pass secrets (tokens, codes, documents) or full payloads.
abstract final class AppLogger {
  static const String _defaultName = 'EasyBooking';

  static void debug(String message, {String name = _defaultName}) {
    if (!kDebugMode) {
      return;
    }
    developer.log(message, name: name, level: 500);
  }

  static void info(String message, {String name = _defaultName}) {
    developer.log(message, name: name, level: 800);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = _defaultName,
  }) {
    developer.log(
      message,
      name: name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String name = _defaultName,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
