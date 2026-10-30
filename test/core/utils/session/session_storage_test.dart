import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';
import 'package:easy_booking/core/utils/storage/storage_keys.dart';

final class _FakeSecureStorage implements SecureStorage {
  _FakeSecureStorage([Map<String, String> initial = const <String, String>{}])
    : values = Map<String, String>.of(initial);

  final Map<String, String> values;
  final List<String> operations = <String>[];

  /// Operations such as `write auth.access_token` or `delete` (any key) that
  /// throw [StorageException].
  final Set<String> failing = <String>{};

  void _check(String operation, String key) {
    if (failing.contains(operation) || failing.contains('$operation $key')) {
      throw StorageException('$operation $key failed');
    }
  }

  @override
  Future<String?> read(String key) async {
    operations.add('read $key');
    _check('read', key);
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    operations.add('write $key');
    _check('write', key);
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    operations.add('delete $key');
    _check('delete', key);
    values.remove(key);
  }
}

/// Minimal in-memory [PreferencesStorage]; only bool values are needed here.
final class _FakePreferences implements PreferencesStorage {
  _FakePreferences({bool? hasLaunchedBefore}) {
    if (hasLaunchedBefore != null) {
      values[StorageKeys.hasLaunchedBefore] = hasLaunchedBefore;
    }
  }

  final Map<String, Object> values = <String, Object>{};
  bool failWrites = false;

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    if (failWrites) {
      throw const StorageException('preferences write failed');
    }
    values[key] = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const Map<String, String> _bothTokens = <String, String>{
  StorageKeys.accessToken: 'access',
  StorageKeys.refreshToken: 'refresh',
};

void main() {
  group('SessionStorageImpl.readTokens on the first launch', () {
    test('clears stored tokens, sets the flag, and returns null', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(_bothTokens);
      final _FakePreferences preferences = _FakePreferences();

      final AuthTokens? tokens = await SessionStorageImpl(
        secureStorage: secure,
        preferences: preferences,
      ).readTokens();

      expect(tokens, isNull);
      expect(secure.values, isEmpty);
      expect(preferences.getBool(StorageKeys.hasLaunchedBefore), isTrue);
      expect(secure.operations, <String>[
        'delete ${StorageKeys.accessToken}',
        'delete ${StorageKeys.refreshToken}',
        'delete ${StorageKeys.accountSetupPending}',
      ]);
    });

    test('also clears a stale account-setup flag', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        ..._bothTokens,
        StorageKeys.accountSetupPending: 'true',
      });
      final SessionStorageImpl storage = SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(),
      );

      expect(await storage.readTokens(), isNull);

      expect(secure.values, isEmpty);
      expect(await storage.readAccountSetupPending(), isFalse);
    });

    test('treats a stored false flag as a first launch', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(_bothTokens);

      final AuthTokens? tokens = await SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(hasLaunchedBefore: false),
      ).readTokens();

      expect(tokens, isNull);
      expect(secure.values, isEmpty);
    });

    test('the next read after the first launch returns saved tokens', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(_bothTokens);
      final SessionStorageImpl storage = SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(),
      );

      expect(await storage.readTokens(), isNull);
      await storage.saveTokens(const AuthTokens(accessToken: 'new'));

      expect(
        await storage.readTokens(),
        const AuthTokens(accessToken: 'new'),
      );
    });

    test('does not set the flag when clearing fails', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(_bothTokens)
        ..failing.add('delete');
      final _FakePreferences preferences = _FakePreferences();

      await expectLater(
        SessionStorageImpl(
          secureStorage: secure,
          preferences: preferences,
        ).readTokens(),
        throwsA(isA<StorageException>()),
      );

      expect(preferences.containsKey(StorageKeys.hasLaunchedBefore), isFalse);
    });

    test('propagates a failure to persist the flag', () async {
      final _FakePreferences preferences = _FakePreferences()
        ..failWrites = true;

      await expectLater(
        SessionStorageImpl(
          secureStorage: _FakeSecureStorage(_bothTokens),
          preferences: preferences,
        ).readTokens(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('SessionStorageImpl.readTokens after the first launch', () {
    SessionStorageImpl storageWith(_FakeSecureStorage secure) {
      return SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(hasLaunchedBefore: true),
      );
    }

    test('returns null when no access token is stored', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        StorageKeys.refreshToken: 'orphan',
      });

      expect(await storageWith(secure).readTokens(), isNull);
      expect(secure.operations, <String>['read ${StorageKeys.accessToken}']);
    });

    test('returns null when the stored access token is empty', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        StorageKeys.accessToken: '',
        StorageKeys.refreshToken: 'refresh',
      });

      expect(await storageWith(secure).readTokens(), isNull);
    });

    test('returns both tokens when stored', () async {
      expect(
        await storageWith(_FakeSecureStorage(_bothTokens)).readTokens(),
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      );
    });

    test('returns a null refresh token when only access is stored', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        StorageKeys.accessToken: 'access',
      });

      expect(
        await storageWith(secure).readTokens(),
        const AuthTokens(accessToken: 'access'),
      );
    });

    test('propagates StorageException from the secure storage', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage()
        ..failing.add('read');

      await expectLater(
        storageWith(secure).readTokens(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('SessionStorageImpl.saveTokens', () {
    SessionStorageImpl storageWith(_FakeSecureStorage secure) {
      return SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(hasLaunchedBefore: true),
      );
    }

    test('writes the refresh token first and the access token last', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage();

      await storageWith(secure).saveTokens(
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      );

      expect(secure.operations, <String>[
        'write ${StorageKeys.refreshToken}',
        'write ${StorageKeys.accessToken}',
      ]);
      expect(secure.values, _bothTokens);
    });

    test('deletes a previous refresh token before writing access', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        StorageKeys.accessToken: 'old',
        StorageKeys.refreshToken: 'old-refresh',
      });

      await storageWith(secure)
          .saveTokens(const AuthTokens(accessToken: 'new'));

      expect(secure.values, <String, String>{StorageKeys.accessToken: 'new'});
      expect(secure.operations, <String>[
        'delete ${StorageKeys.refreshToken}',
        'write ${StorageKeys.accessToken}',
      ]);
    });

    test('a failed access write clears the tokens and rethrows', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        StorageKeys.accessToken: 'old',
      })..failing.add('write ${StorageKeys.accessToken}');

      await expectLater(
        storageWith(secure).saveTokens(
          const AuthTokens(accessToken: 'new', refreshToken: 'new-refresh'),
        ),
        throwsA(isA<StorageException>()),
      );

      expect(secure.values, isEmpty);
      expect(secure.operations, <String>[
        'write ${StorageKeys.refreshToken}',
        'write ${StorageKeys.accessToken}',
        'delete ${StorageKeys.accessToken}',
        'delete ${StorageKeys.refreshToken}',
        'delete ${StorageKeys.accountSetupPending}',
      ]);
    });

    test(
      'a failed stale-refresh delete leaves no restorable session',
      () async {
        final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
          StorageKeys.accessToken: 'old',
          StorageKeys.refreshToken: 'old-refresh',
        })..failing.add('delete ${StorageKeys.refreshToken}');
        final SessionStorageImpl storage = storageWith(secure);

        await expectLater(
          storage.saveTokens(const AuthTokens(accessToken: 'new')),
          throwsA(isA<StorageException>()),
        );

        expect(secure.values, isNot(contains(StorageKeys.accessToken)));
        expect(await storage.readTokens(), isNull);
      },
    );

    test('rethrows the original failure when cleanup also fails', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage()
        ..failing.addAll(<String>['write', 'delete']);

      await expectLater(
        storageWith(
          secure,
        ).saveTokens(const AuthTokens(accessToken: 'a', refreshToken: 'r')),
        throwsA(
          isA<StorageException>().having(
            (StorageException e) => e.message,
            'message',
            contains('write'),
          ),
        ),
      );
    });
  });

  group('SessionStorageImpl.clearTokens', () {
    test(
      'deletes the access token, the refresh token, then the flag',
      () async {
        final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
          ..._bothTokens,
          StorageKeys.accountSetupPending: 'true',
          'other': 'kept',
        });

        await SessionStorageImpl(
          secureStorage: secure,
          preferences: _FakePreferences(hasLaunchedBefore: true),
        ).clearTokens();

        expect(secure.values, <String, String>{'other': 'kept'});
        expect(secure.operations, <String>[
          'delete ${StorageKeys.accessToken}',
          'delete ${StorageKeys.refreshToken}',
          'delete ${StorageKeys.accountSetupPending}',
        ]);
      },
    );

    test('a failed flag delete still removes both tokens first', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        ..._bothTokens,
        StorageKeys.accountSetupPending: 'true',
      })..failing.add('delete ${StorageKeys.accountSetupPending}');
      final SessionStorageImpl storage = SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(hasLaunchedBefore: true),
      );

      await expectLater(
        storage.clearTokens(),
        throwsA(isA<StorageException>()),
      );

      expect(await storage.readTokens(), isNull);
    });

    test('propagates StorageException from the secure storage', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage()
        ..failing.add('delete');

      await expectLater(
        SessionStorageImpl(
          secureStorage: secure,
          preferences: _FakePreferences(hasLaunchedBefore: true),
        ).clearTokens(),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('SessionStorageImpl account-setup flag', () {
    SessionStorageImpl storageWith(_FakeSecureStorage secure) {
      return SessionStorageImpl(
        secureStorage: secure,
        preferences: _FakePreferences(hasLaunchedBefore: true),
      );
    }

    test('reads false when the flag is missing', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage();

      expect(await storageWith(secure).readAccountSetupPending(), isFalse);
      expect(secure.operations, <String>[
        'read ${StorageKeys.accountSetupPending}',
      ]);
    });

    test('reads true only for the stored value true', () async {
      for (final (String value, bool expected) in <(String, bool)>[
        ('true', true),
        ('false', false),
        ('TRUE', false),
        ('1', false),
        ('', false),
      ]) {
        final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
          StorageKeys.accountSetupPending: value,
        });

        expect(
          await storageWith(secure).readAccountSetupPending(),
          expected,
          reason: value,
        );
      }
    });

    test('saving true writes the string true under its key', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage();

      await storageWith(secure).saveAccountSetupPending(true);

      expect(secure.values, <String, String>{
        StorageKeys.accountSetupPending: 'true',
      });
      expect(secure.operations, <String>[
        'write ${StorageKeys.accountSetupPending}',
      ]);
    });

    test('saving false deletes the key', () async {
      final _FakeSecureStorage secure = _FakeSecureStorage(<String, String>{
        ..._bothTokens,
        StorageKeys.accountSetupPending: 'true',
      });

      await storageWith(secure).saveAccountSetupPending(false);

      expect(secure.values, _bothTokens);
      expect(secure.operations, <String>[
        'delete ${StorageKeys.accountSetupPending}',
      ]);
    });

    test('a saved flag reads back', () async {
      final SessionStorageImpl storage = storageWith(_FakeSecureStorage());

      await storage.saveAccountSetupPending(true);
      expect(await storage.readAccountSetupPending(), isTrue);

      await storage.saveAccountSetupPending(false);
      expect(await storage.readAccountSetupPending(), isFalse);
    });

    test('propagates StorageException on read, write and delete', () async {
      for (final String operation in <String>['read', 'write', 'delete']) {
        final SessionStorageImpl storage = storageWith(
          _FakeSecureStorage()..failing.add(operation),
        );
        final Future<void> call = switch (operation) {
          'read' => storage.readAccountSetupPending(),
          'write' => storage.saveAccountSetupPending(true),
          _ => storage.saveAccountSetupPending(false),
        };

        await expectLater(
          call,
          throwsA(isA<StorageException>()),
          reason: operation,
        );
      }
    });
  });

  group('AuthTokens', () {
    test('toString does not reveal the tokens', () {
      const AuthTokens tokens = AuthTokens(
        accessToken: 'secret-access',
        refreshToken: 'secret-refresh',
      );

      expect(tokens.toString(), isNot(contains('secret')));
    });
  });
}
