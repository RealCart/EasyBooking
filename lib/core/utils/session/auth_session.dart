import 'package:flutter/foundation.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_mapper.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';

/// Single owner of the signed-in state.
///
/// Keeps the tokens in memory for request headers and notifies listeners
/// (the router) when the user signs in or out or finishes account setup.
final class AuthSession extends ChangeNotifier {
  AuthSession({required this._sessionStorage});

  final SessionStorage _sessionStorage;

  AuthTokens? _tokens;
  bool _isAccountSetupPending = false;

  AuthTokens? get tokens => _tokens;

  bool get isAuthenticated => _tokens != null;

  /// A new user is signed in but has not created the account yet. The router
  /// keeps such a user on account setup, also after an app restart.
  bool get isAccountSetupPending => isAuthenticated && _isAccountSetupPending;

  /// Loads the persisted session. Call once before the first route is
  /// resolved.
  ///
  /// An unreadable storage is treated as signed out so the app still starts.
  Future<void> restore() async {
    try {
      final AuthTokens? tokens = await _sessionStorage.readTokens();
      final bool isAccountSetupPending =
          tokens != null && await _sessionStorage.readAccountSetupPending();
      _update(tokens: tokens, isAccountSetupPending: isAccountSetupPending);
    } on StorageException catch (exception, stackTrace) {
      AppLogger.warning(
        'Could not restore the session; starting signed out',
        error: exception,
        stackTrace: stackTrace,
      );
      _update(tokens: null, isAccountSetupPending: false);
    }
  }

  /// Persists the session first; it changes in memory only after both writes
  /// succeed. The flag is written before the tokens because the tokens are
  /// what marks a session as restorable. A failed write is returned as a
  /// `StorageFailure` and leaves the session unchanged.
  Future<Either<Failure, void>> signIn(
    AuthTokens tokens, {
    bool isAccountSetupPending = false,
  }) async {
    try {
      await _sessionStorage.saveAccountSetupPending(isAccountSetupPending);
      await _sessionStorage.saveTokens(tokens);
    } on StorageException catch (exception, stackTrace) {
      return Either<Failure, void>.left(
        mapExceptionToFailure(exception, stackTrace),
      );
    }
    _update(tokens: tokens, isAccountSetupPending: isAccountSetupPending);
    return const Either<Failure, void>.right(null);
  }

  /// Clears the account-setup flag after the account was created.
  ///
  /// The account already exists on the server, so the user must not stay on
  /// setup when only the local write fails: memory is updated first and a
  /// write failure is logged, not thrown. After a restart the user would see
  /// setup again, which is better than being stuck now.
  Future<void> completeAccountSetup() async {
    if (!isAccountSetupPending) {
      return;
    }
    _update(tokens: _tokens, isAccountSetupPending: false);
    try {
      await _sessionStorage.saveAccountSetupPending(false);
    } on StorageException catch (exception, stackTrace) {
      AppLogger.warning(
        'Account setup completed but the flag was not cleared',
        error: exception,
        stackTrace: stackTrace,
      );
    }
  }

  /// Signs out in memory first, so new requests stop sending the token and
  /// concurrent 401s return early, then clears the storage. A failed clear
  /// is returned as a `StorageFailure`; the session stays signed out.
  Future<Either<Failure, void>> signOut() async {
    if (_tokens == null) {
      return const Either<Failure, void>.right(null);
    }
    _update(tokens: null, isAccountSetupPending: false);
    try {
      await _sessionStorage.clearTokens();
    } on StorageException catch (exception, stackTrace) {
      return Either<Failure, void>.left(
        mapExceptionToFailure(exception, stackTrace),
      );
    }
    return const Either<Failure, void>.right(null);
  }

  void _update({
    required AuthTokens? tokens,
    required bool isAccountSetupPending,
  }) {
    if (_tokens == tokens && _isAccountSetupPending == isAccountSetupPending) {
      return;
    }
    _tokens = tokens;
    _isAccountSetupPending = isAccountSetupPending;
    notifyListeners();
  }
}
