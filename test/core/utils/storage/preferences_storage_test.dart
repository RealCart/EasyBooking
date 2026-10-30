import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';

/// In-memory [SharedPreferencesWithCache] that can hold or fail writes.
///
/// The platform-backed instance needs `SharedPreferencesAsyncPlatform`, which
/// lives in a package that is not a direct dependency of this project.
final class _FakePreferences implements SharedPreferencesWithCache {
  _FakePreferences({
    Map<String, Object> initial = const <String, Object>{},
    this.writeGate,
    this.writeError,
  }) : values = Map<String, Object>.of(initial);

  final Map<String, Object> values;

  /// When set, every write waits for it before storing.
  final Completer<void>? writeGate;

  /// When set, every write throws it.
  final PlatformException? writeError;

  final List<String> writes = <String>[];

  Future<void> _write(String description, void Function() apply) async {
    writes.add(description);
    final Completer<void>? gate = writeGate;
    if (gate != null) {
      await gate.future;
    }
    final PlatformException? error = writeError;
    if (error != null) {
      throw error;
    }
    apply();
  }

  @override
  bool containsKey(String key) => values.containsKey(key);

  @override
  Set<String> get keys => values.keys.toSet();

  @override
  Object? get(String key) => values[key];

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  double? getDouble(String key) => values[key] as double?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  List<String>? getStringList(String key) => values[key] as List<String>?;

  @override
  Future<void> setBool(String key, bool value) {
    return _write('setBool $key', () => values[key] = value);
  }

  @override
  Future<void> setInt(String key, int value) {
    return _write('setInt $key', () => values[key] = value);
  }

  @override
  Future<void> setDouble(String key, double value) {
    return _write('setDouble $key', () => values[key] = value);
  }

  @override
  Future<void> setString(String key, String value) {
    return _write('setString $key', () => values[key] = value);
  }

  @override
  Future<void> setStringList(String key, List<String> value) {
    return _write('setStringList $key', () => values[key] = value);
  }

  @override
  Future<void> remove(String key) {
    return _write('remove $key', () => values.remove(key));
  }

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> reloadCache() async {}
}

void main() {
  group('PreferencesStorageImpl reads', () {
    test('typed getters return null for a missing key', () {
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(),
      );

      expect(storage.containsKey('missing'), isFalse);
      expect(storage.getString('missing'), isNull);
      expect(storage.getBool('missing'), isNull);
      expect(storage.getInt('missing'), isNull);
      expect(storage.getDouble('missing'), isNull);
      expect(storage.getStringList('missing'), isNull);
    });

    test('typed getters return stored values of the matching type', () {
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(
          initial: <String, Object>{
            'string': 'value',
            'bool': false,
            'int': 0,
            'double': 1.5,
            'list': <String>['a', 'b'],
            'empty': '',
          },
        ),
      );

      expect(storage.containsKey('string'), isTrue);
      expect(storage.getString('string'), 'value');
      expect(storage.getString('empty'), '');
      expect(storage.getBool('bool'), isFalse);
      expect(storage.getInt('int'), 0);
      expect(storage.getDouble('double'), 1.5);
      expect(storage.getStringList('list'), <String>['a', 'b']);
    });

    test('getStringList returns an unmodifiable copy', () {
      final List<String> stored = <String>['a'];
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(
          initial: <String, Object>{'list': stored},
        ),
      );

      final List<String> result = storage.getStringList('list')!;

      expect(() => result.add('b'), throwsUnsupportedError);
      expect(stored, <String>['a']);
    });

    test('getStringList accepts a List<Object?> holding only strings', () {
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(
          initial: <String, Object>{
            'list': <Object?>['a', 'b'],
          },
        ),
      );

      expect(storage.getStringList('list'), <String>['a', 'b']);
    });

    test('typed getters throw StorageException for a wrong type', () {
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(
          initial: <String, Object>{
            'string': 'value',
            'int': 1,
            'mixedList': <Object?>['a', 1],
          },
        ),
      );

      expect(() => storage.getInt('string'), throwsA(isA<StorageException>()));
      expect(
        () => storage.getBool('string'),
        throwsA(isA<StorageException>()),
      );
      expect(
        () => storage.getDouble('string'),
        throwsA(isA<StorageException>()),
      );
      expect(() => storage.getString('int'), throwsA(isA<StorageException>()));
      expect(
        () => storage.getStringList('string'),
        throwsA(isA<StorageException>()),
      );
      expect(
        () => storage.getStringList('mixedList'),
        throwsA(isA<StorageException>()),
      );
    });
  });

  group('PreferencesStorageImpl writes', () {
    test('setters store values readable by the getters', () async {
      final _FakePreferences preferences = _FakePreferences();
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: preferences,
      );

      await storage.setString('s', 'v');
      await storage.setBool('b', true);
      await storage.setInt('i', 3);
      await storage.setDouble('d', 2.5);
      await storage.setStringList('l', <String>['x']);

      expect(preferences.writes, <String>[
        'setString s',
        'setBool b',
        'setInt i',
        'setDouble d',
        'setStringList l',
      ]);
      expect(storage.getString('s'), 'v');
      expect(storage.getBool('b'), isTrue);
      expect(storage.getInt('i'), 3);
      expect(storage.getDouble('d'), 2.5);
      expect(storage.getStringList('l'), <String>['x']);
    });

    test('remove deletes the key', () async {
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: _FakePreferences(initial: <String, Object>{'k': 'v'}),
      );

      await storage.remove('k');

      expect(storage.containsKey('k'), isFalse);
      expect(storage.getString('k'), isNull);
    });

    test(
      'a write completes only after the underlying write completes',
      () async {
        final _FakePreferences preferences = _FakePreferences(
          writeGate: Completer<void>(),
        );
        final PreferencesStorageImpl storage = PreferencesStorageImpl(
          preferences: preferences,
        );
        bool isDone = false;

        final Future<void> write = storage
            .setString('k', 'v')
            .then((_) => isDone = true);
        await pumpEventQueue();

        expect(isDone, isFalse);

        preferences.writeGate!.complete();
        await write;

        expect(isDone, isTrue);
        expect(storage.getString('k'), 'v');
      },
    );

    test('a PlatformException on write becomes StorageException', () async {
      final _FakePreferences preferences = _FakePreferences(
        writeError: PlatformException(code: 'disk_full'),
      );
      final PreferencesStorageImpl storage = PreferencesStorageImpl(
        preferences: preferences,
      );

      await expectLater(
        storage.setString('k', 'v'),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        storage.setBool('k', true),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        storage.setInt('k', 1),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        storage.setDouble('k', 1),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        storage.setStringList('k', <String>[]),
        throwsA(isA<StorageException>()),
      );
      await expectLater(storage.remove('k'), throwsA(isA<StorageException>()));
    });
  });
}
