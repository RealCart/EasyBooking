import 'package:flutter/foundation.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';

/// Single owner of the signed-in state.
///
/// Keeps the tokens in memory for request headers and notifies listeners
/// (the router) when the user signs in or out.
final class AuthSession extends ChangeNotifier {
  AuthSession({required this._sessionStorage});

  final SessionStorage _sessionStorage;

  AuthTokens? _tokens;

  AuthTokens? get tokens => _tokens;

  bool get isAuthenticated => _tokens != null;

  /// Loads persisted tokens. Call once before the first route is resolved.
  ///
  /// An unreadable storage is treated as signed out so the app still starts.
  Future<void> restore() async {
    try {
      _setTokens(await _sessionStorage.readTokens());
    } on StorageException catch (exception, stackTrace) {
      AppLogger.warning(
        'Could not restore the session; starting signed out',
        error: exception,
        stackTrace: stackTrace,
      );
      _setTokens(null);
    }
  }

  /// Persists [tokens] first; the session changes only after a successful
  /// write. Throws `StorageException` when the write fails.
  Future<void> signIn(AuthTokens tokens) async {
    await _sessionStorage.saveTokens(tokens);
    _setTokens(tokens);
  }

  /// Signs out in memory first, so new requests stop sending the token and
  /// concurrent 401s return early, then clears the storage. Throws
  /// `StorageException` when clearing fails; the session stays signed out.
  Future<void> signOut() async {
    if (_tokens == null) {
      return;
    }
    _setTokens(null);
    await _sessionStorage.clearTokens();
  }

  void _setTokens(AuthTokens? tokens) {
    if (_tokens == tokens) {
      return;
    }
    _tokens = tokens;
    notifyListeners();
  }
}
