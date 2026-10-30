import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';

/// Non-sensitive key-value storage. Use `SecureStorage` for credentials.
///
/// Getters return `null` when the key is missing and throw
/// [StorageException] when the stored value has another type.
abstract interface class PreferencesStorage {
  bool containsKey(String key);

  String? getString(String key);

  bool? getBool(String key);

  int? getInt(String key);

  double? getDouble(String key);

  List<String>? getStringList(String key);

  Future<void> setString(String key, String value);

  Future<void> setBool(String key, bool value);

  Future<void> setInt(String key, int value);

  Future<void> setDouble(String key, double value);

  Future<void> setStringList(String key, List<String> value);

  Future<void> remove(String key);
}

final class PreferencesStorageImpl implements PreferencesStorage {
  const PreferencesStorageImpl({required this._preferences});

  final SharedPreferencesWithCache _preferences;

  /// Loads the cache once; register the result with `registerSingletonAsync`.
  static Future<PreferencesStorageImpl> create() async {
    final SharedPreferencesWithCache preferences =
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(),
        );
    return PreferencesStorageImpl(preferences: preferences);
  }

  @override
  bool containsKey(String key) => _preferences.containsKey(key);

  @override
  String? getString(String key) => _read<String>(key);

  @override
  bool? getBool(String key) => _read<bool>(key);

  @override
  int? getInt(String key) => _read<int>(key);

  @override
  double? getDouble(String key) => _read<double>(key);

  @override
  List<String>? getStringList(String key) {
    final Object? value = _preferences.get(key);
    if (value == null) {
      return null;
    }
    if (value is List<Object?> &&
        value.every((Object? item) => item is String)) {
      return List<String>.unmodifiable(value);
    }
    throw StorageException('Expected List<String> for "$key"');
  }

  @override
  Future<void> setString(String key, String value) {
    return _write(key, () => _preferences.setString(key, value));
  }

  @override
  Future<void> setBool(String key, bool value) {
    return _write(key, () => _preferences.setBool(key, value));
  }

  @override
  Future<void> setInt(String key, int value) {
    return _write(key, () => _preferences.setInt(key, value));
  }

  @override
  Future<void> setDouble(String key, double value) {
    return _write(key, () => _preferences.setDouble(key, value));
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    return _write(key, () => _preferences.setStringList(key, value));
  }

  @override
  Future<void> remove(String key) {
    return _write(key, () => _preferences.remove(key));
  }

  T? _read<T extends Object>(String key) {
    final Object? value = _preferences.get(key);
    if (value == null) {
      return null;
    }
    if (value is T) {
      return value;
    }
    throw StorageException(
      'Expected $T for "$key", found ${value.runtimeType}',
    );
  }

  Future<void> _write(String key, Future<void> Function() write) async {
    try {
      await write();
    } on PlatformException catch (exception) {
      throw StorageException('Failed to write "$key": ${exception.code}');
    }
  }
}
