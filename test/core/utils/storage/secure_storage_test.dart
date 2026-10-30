import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';

/// [FlutterSecureStorage] whose every operation throws [error].
final class _ThrowingSecureStorage implements FlutterSecureStorage {
  _ThrowingSecureStorage(this.error);

  final Object error;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw error;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw error;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    throw error;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SecureStorageImpl with the in-memory platform', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'existing': 'value',
      });
    });

    test('read returns the stored value', () async {
      const SecureStorageImpl storage = SecureStorageImpl(
        storage: FlutterSecureStorage(),
      );

      expect(await storage.read('existing'), 'value');
    });

    test('read returns null for a missing key', () async {
      const SecureStorageImpl storage = SecureStorageImpl(
        storage: FlutterSecureStorage(),
      );

      expect(await storage.read('missing'), isNull);
    });

    test('write then read returns the written value', () async {
      const SecureStorageImpl storage = SecureStorageImpl(
        storage: FlutterSecureStorage(),
      );

      await storage.write(key: 'token', value: 'abc');

      expect(await storage.read('token'), 'abc');
    });

    test('delete removes the key', () async {
      const SecureStorageImpl storage = SecureStorageImpl(
        storage: FlutterSecureStorage(),
      );

      await storage.delete('existing');

      expect(await storage.read('existing'), isNull);
    });
  });

  group('SecureStorageImpl failures', () {
    test(
      'PlatformException becomes StorageException for every operation',
      () async {
        final SecureStorageImpl storage = SecureStorageImpl(
          storage: _ThrowingSecureStorage(PlatformException(code: 'locked')),
        );

        await expectLater(storage.read('k'), throwsA(isA<StorageException>()));
        await expectLater(
          storage.write(key: 'k', value: 'v'),
          throwsA(isA<StorageException>()),
        );
        await expectLater(
          storage.delete('k'),
          throwsA(isA<StorageException>()),
        );
      },
    );

    test('the StorageException message names the operation and code', () async {
      final SecureStorageImpl storage = SecureStorageImpl(
        storage: _ThrowingSecureStorage(PlatformException(code: 'locked')),
      );

      await expectLater(
        storage.write(key: 'k', value: 'v'),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.message,
            'message',
            allOf(contains('write'), contains('"k"'), contains('locked')),
          ),
        ),
      );
    });

    test('non-platform errors propagate unchanged', () async {
      final SecureStorageImpl storage = SecureStorageImpl(
        storage: _ThrowingSecureStorage(StateError('bug')),
      );

      await expectLater(storage.read('k'), throwsA(isA<StateError>()));
    });
  });
}
