import 'dart:async';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';

/// In-memory [SessionStorage] with switchable failures and optional gates
/// that hold writes until the test releases them.
///
/// Every call is appended to [operations] (for example `saveTokens` or
/// `saveAccountSetupPending(true)`) so tests can check the write order.
final class FakeSessionStorage implements SessionStorage {
  FakeSessionStorage({
    this.storedTokens,
    this.storedAccountSetupPending = false,
  });

  AuthTokens? storedTokens;
  bool storedAccountSetupPending;

  final List<String> operations = <String>[];

  /// [readTokens] throws.
  bool failReads = false;

  /// [saveTokens] throws.
  bool failWrites = false;

  /// [clearTokens] throws.
  bool failClears = false;

  /// [readAccountSetupPending] throws.
  bool failFlagReads = false;

  /// [saveAccountSetupPending] throws.
  bool failFlagWrites = false;

  /// When set, [saveTokens] waits for this future before storing.
  Future<void>? saveGate;

  /// When set, [clearTokens] waits for this future before clearing.
  Future<void>? clearGate;

  /// When set, [saveAccountSetupPending] waits for this future before
  /// storing.
  Future<void>? flagGate;

  int readCount = 0;
  int saveCount = 0;
  int clearCount = 0;
  int flagReadCount = 0;
  int flagSaveCount = 0;

  @override
  Future<AuthTokens?> readTokens() async {
    readCount++;
    operations.add('readTokens');
    if (failReads) {
      throw const StorageException('read failed');
    }
    return storedTokens;
  }

  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    saveCount++;
    operations.add('saveTokens');
    final Future<void>? gate = saveGate;
    if (gate != null) {
      await gate;
    }
    if (failWrites) {
      throw const StorageException('write failed');
    }
    storedTokens = tokens;
  }

  /// Also removes the account-setup flag, as the real storage does.
  @override
  Future<void> clearTokens() async {
    clearCount++;
    operations.add('clearTokens');
    final Future<void>? gate = clearGate;
    if (gate != null) {
      await gate;
    }
    if (failClears) {
      throw const StorageException('clear failed');
    }
    storedTokens = null;
    storedAccountSetupPending = false;
  }

  @override
  Future<bool> readAccountSetupPending() async {
    flagReadCount++;
    operations.add('readAccountSetupPending');
    if (failFlagReads) {
      throw const StorageException('flag read failed');
    }
    return storedAccountSetupPending;
  }

  @override
  Future<void> saveAccountSetupPending(bool isPending) async {
    flagSaveCount++;
    operations.add('saveAccountSetupPending($isPending)');
    final Future<void>? gate = flagGate;
    if (gate != null) {
      await gate;
    }
    if (failFlagWrites) {
      throw const StorageException('flag write failed');
    }
    storedAccountSetupPending = isPending;
  }
}
