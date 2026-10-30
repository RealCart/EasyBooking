import 'dart:async';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';

/// In-memory [SessionStorage] with switchable failures and an optional gate
/// that holds writes until the test releases them.
final class FakeSessionStorage implements SessionStorage {
  FakeSessionStorage({this.storedTokens});

  AuthTokens? storedTokens;

  bool failReads = false;
  bool failWrites = false;
  bool failClears = false;

  /// When set, [saveTokens] waits for this future before storing.
  Future<void>? saveGate;

  /// When set, [clearTokens] waits for this future before clearing.
  Future<void>? clearGate;

  int readCount = 0;
  int saveCount = 0;
  int clearCount = 0;

  @override
  Future<AuthTokens?> readTokens() async {
    readCount++;
    if (failReads) {
      throw const StorageException('read failed');
    }
    return storedTokens;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    saveCount++;
    final Future<void>? gate = saveGate;
    if (gate != null) {
      await gate;
    }
    if (failWrites) {
      throw const StorageException('write failed');
    }
    storedTokens = tokens;
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    final Future<void>? gate = clearGate;
    if (gate != null) {
      await gate;
    }
    if (failClears) {
      throw const StorageException('clear failed');
    }
    storedTokens = null;
  }
}
