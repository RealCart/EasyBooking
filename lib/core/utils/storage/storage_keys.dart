/// Every persisted key in one place.
///
/// Renaming a key loses the stored value; add a migration instead.
abstract final class StorageKeys {
  // Preferences.
  /// Missing on a fresh install, including a reinstall.
  static const String hasLaunchedBefore = 'app.has_launched_before';

  // Secure storage.
  static const String accessToken = 'auth.access_token';
  static const String refreshToken = 'auth.refresh_token';
}
