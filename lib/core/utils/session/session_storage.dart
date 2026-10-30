import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';
import 'package:easy_booking/core/utils/storage/storage_keys.dart';

/// Persists [AuthTokens] and the account-setup flag in [SecureStorage].
///
/// Throws `StorageException` when the platform storage fails.
abstract interface class SessionStorage {
  /// Returns `null` when no access token is stored.
  Future<AuthTokens?> readTokens();

  Future<void> saveTokens(AuthTokens tokens);

  /// Also removes the account-setup flag.
  Future<void> clearTokens();

  /// Returns `false` when the flag is missing.
  Future<bool> readAccountSetupPending();

  Future<void> saveAccountSetupPending(bool isPending);
}

final class SessionStorageImpl implements SessionStorage {
  const SessionStorageImpl({
    required this._secureStorage,
    required this._preferences,
  });

  static const String _pendingValue = 'true';

  final SecureStorage _secureStorage;
  final PreferencesStorage _preferences;

  /// On the first launch after an install, clears the tokens and returns
  /// `null`: the iOS Keychain keeps them after the app is deleted, and a
  /// reinstall must not restore the previous session.
  @override
  Future<AuthTokens?> readTokens() async {
    if (!(_preferences.getBool(StorageKeys.hasLaunchedBefore) ?? false)) {
      await clearTokens();
      await _preferences.setBool(StorageKeys.hasLaunchedBefore, true);
      return null;
    }
    final String? accessToken = await _secureStorage.read(
      StorageKeys.accessToken,
    );
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final String? refreshToken = await _secureStorage.read(
      StorageKeys.refreshToken,
    );
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  /// The access token is written last because its presence is what
  /// [readTokens] treats as signed in. If any write fails, the stored tokens
  /// are cleared so the next launch does not restore a half-written session.
  @override
  Future<void> saveTokens(AuthTokens tokens) async {
    try {
      final String? refreshToken = tokens.refreshToken;
      if (refreshToken == null) {
        // Do not keep a refresh token that belongs to a previous session.
        await _secureStorage.delete(StorageKeys.refreshToken);
      } else {
        await _secureStorage.write(
          key: StorageKeys.refreshToken,
          value: refreshToken,
        );
      }
      await _secureStorage.write(
        key: StorageKeys.accessToken,
        value: tokens.accessToken,
      );
    } on StorageException {
      await _clearIgnoringErrors();
      rethrow;
    }
  }

  /// The access token is deleted first, so a failure afterwards cannot leave
  /// a session that [readTokens] would restore.
  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _secureStorage.delete(StorageKeys.accountSetupPending);
  }

  @override
  Future<bool> readAccountSetupPending() async {
    final String? value = await _secureStorage.read(
      StorageKeys.accountSetupPending,
    );
    return value == _pendingValue;
  }

  @override
  Future<void> saveAccountSetupPending(bool isPending) {
    if (isPending) {
      return _secureStorage.write(
        key: StorageKeys.accountSetupPending,
        value: _pendingValue,
      );
    }
    return _secureStorage.delete(StorageKeys.accountSetupPending);
  }

  Future<void> _clearIgnoringErrors() async {
    try {
      await clearTokens();
    } on StorageException catch (exception, stackTrace) {
      AppLogger.warning(
        'Could not clear partially written tokens',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }
}
