import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';

/// Encrypted storage for credentials and other sensitive values.
///
/// Every method throws [StorageException] when the platform call fails.
abstract interface class SecureStorage {
  /// Returns `null` when [key] is missing.
  Future<String?> read(String key);

  Future<void> write({required String key, required String value});

  Future<void> delete(String key);
}

final class SecureStorageImpl implements SecureStorage {
  const SecureStorageImpl({required this._storage});

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) {
    return _guard('read', key, () => _storage.read(key: key));
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _guard('write', key, () => _storage.write(key: key, value: value));
  }

  @override
  Future<void> delete(String key) {
    return _guard('delete', key, () => _storage.delete(key: key));
  }

  Future<T> _guard<T>(
    String operation,
    String key,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on PlatformException catch (exception) {
      throw StorageException(
        'Secure storage $operation failed for "$key": ${exception.code}',
      );
    }
  }
}
