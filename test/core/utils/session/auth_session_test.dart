import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/app_exception.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';

import '../../../helpers/fake_session_storage.dart';

const AuthTokens _tokens = AuthTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
);
const AuthTokens _otherTokens = AuthTokens(accessToken: 'other');

void main() {
  late FakeSessionStorage storage;
  late AuthSession session;
  late int notifications;

  setUp(() {
    storage = FakeSessionStorage();
    session = AuthSession(sessionStorage: storage);
    notifications = 0;
    session.addListener(() => notifications++);
  });

  tearDown(() => session.dispose());

  test('starts signed out', () {
    expect(session.isAuthenticated, isFalse);
    expect(session.isAccountSetupPending, isFalse);
    expect(session.tokens, isNull);
  });

  group('restore', () {
    test('loads stored tokens and notifies once', () async {
      storage.storedTokens = _tokens;

      await session.restore();

      expect(session.isAuthenticated, isTrue);
      expect(session.tokens, _tokens);
      expect(notifications, 1);
    });

    test('with nothing stored stays signed out without notifying', () async {
      await session.restore();

      expect(session.isAuthenticated, isFalse);
      expect(notifications, 0);
    });

    test(
      'treats a StorageException as signed out and does not throw',
      () async {
        storage.failReads = true;

        await expectLater(session.restore(), completes);

        expect(session.isAuthenticated, isFalse);
        expect(notifications, 0);
      },
    );

    test('restores a pending account setup with the tokens', () async {
      storage
        ..storedTokens = _tokens
        ..storedAccountSetupPending = true;

      await session.restore();

      expect(session.tokens, _tokens);
      expect(session.isAccountSetupPending, isTrue);
      expect(notifications, 1);
    });

    test('reads the flag only after tokens were found', () async {
      storage
        ..storedTokens = _tokens
        ..storedAccountSetupPending = false;

      await session.restore();

      expect(storage.operations, <String>[
        'readTokens',
        'readAccountSetupPending',
      ]);
      expect(session.isAccountSetupPending, isFalse);
    });

    test('ignores a stored flag without tokens', () async {
      storage.storedAccountSetupPending = true;

      await session.restore();

      expect(storage.flagReadCount, 0);
      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 0);
    });

    test('a flag read failure starts signed out', () async {
      storage
        ..storedTokens = _tokens
        ..failFlagReads = true;

      await expectLater(session.restore(), completes);

      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 0);
    });

    test('a StorageException after sign-in clears the session', () async {
      await session.signIn(_tokens);
      storage.failReads = true;

      await session.restore();

      expect(session.isAuthenticated, isFalse);
      expect(notifications, 2);
    });
  });

  group('signIn', () {
    test('persists tokens before changing the session', () async {
      final Completer<void> gate = Completer<void>();
      storage.saveGate = gate.future;

      final Future<void> signIn = session.signIn(_tokens);
      await pumpEventQueue();

      expect(storage.saveCount, 1);
      expect(session.isAuthenticated, isFalse);
      expect(notifications, 0);

      gate.complete();
      await signIn;

      expect(storage.storedTokens, _tokens);
      expect(session.tokens, _tokens);
      expect(notifications, 1);
    });

    test('does not change the session when the write fails', () async {
      storage.failWrites = true;

      await expectLater(
        session.signIn(_tokens),
        throwsA(isA<StorageException>()),
      );

      expect(session.isAuthenticated, isFalse);
      expect(notifications, 0);
    });

    test('a failed write keeps the previous session', () async {
      await session.signIn(_tokens);
      storage.failWrites = true;

      await expectLater(
        session.signIn(_otherTokens),
        throwsA(isA<StorageException>()),
      );

      expect(session.tokens, _tokens);
      expect(notifications, 1);
    });

    test('signing in with equal tokens does not notify again', () async {
      await session.signIn(_tokens);
      await session.signIn(
        const AuthTokens(accessToken: 'access', refreshToken: 'refresh'),
      );

      expect(notifications, 1);
    });

    test('signing in with new tokens replaces them and notifies', () async {
      await session.signIn(_tokens);
      await session.signIn(_otherTokens);

      expect(session.tokens, _otherTokens);
      expect(notifications, 2);
    });

    test('is not pending by default and persists the flag as false', () async {
      await session.signIn(_tokens);

      expect(session.isAccountSetupPending, isFalse);
      expect(storage.operations, <String>[
        'saveAccountSetupPending(false)',
        'saveTokens',
      ]);
    });

    test('writes the pending flag first, then the tokens', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);

      expect(storage.operations, <String>[
        'saveAccountSetupPending(true)',
        'saveTokens',
      ]);
      expect(storage.storedAccountSetupPending, isTrue);
      expect(storage.storedTokens, _tokens);
      expect(session.isAuthenticated, isTrue);
      expect(session.isAccountSetupPending, isTrue);
      expect(notifications, 1);
    });

    test('changes nothing in memory until both writes complete', () async {
      final Completer<void> flagGate = Completer<void>();
      final Completer<void> tokenGate = Completer<void>();
      storage
        ..flagGate = flagGate.future
        ..saveGate = tokenGate.future;

      final Future<void> signIn = session.signIn(
        _tokens,
        isAccountSetupPending: true,
      );
      await pumpEventQueue();

      expect(storage.saveCount, 0, reason: 'tokens wait for the flag');
      expect(session.isAuthenticated, isFalse);

      flagGate.complete();
      await pumpEventQueue();

      expect(storage.saveCount, 1);
      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 0);

      tokenGate.complete();
      await signIn;

      expect(session.isAccountSetupPending, isTrue);
      expect(notifications, 1);
    });

    test('a failed flag write throws before the tokens are written', () async {
      storage.failFlagWrites = true;

      await expectLater(
        session.signIn(_tokens, isAccountSetupPending: true),
        throwsA(isA<StorageException>()),
      );

      expect(storage.saveCount, 0);
      expect(storage.storedTokens, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 0);
    });

    test('a failed token write after the flag keeps the session', () async {
      storage.failWrites = true;

      await expectLater(
        session.signIn(_tokens, isAccountSetupPending: true),
        throwsA(isA<StorageException>()),
      );

      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 0);
    });

    test('the same tokens with a new pending flag notify again', () async {
      await session.signIn(_tokens);
      await session.signIn(_tokens, isAccountSetupPending: true);

      expect(session.isAccountSetupPending, isTrue);
      expect(notifications, 2);
    });
  });

  group('completeAccountSetup', () {
    test('is a no-op when signed out', () async {
      await session.completeAccountSetup();

      expect(storage.flagSaveCount, 0);
      expect(notifications, 0);
    });

    test('is a no-op when setup is not pending', () async {
      await session.signIn(_tokens);
      final int savesBefore = storage.flagSaveCount;

      await session.completeAccountSetup();

      expect(storage.flagSaveCount, savesBefore);
      expect(notifications, 1);
    });

    test('clears the flag in memory and notifies before persisting', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);
      final Completer<void> gate = Completer<void>();
      storage.flagGate = gate.future;

      final Future<void> complete = session.completeAccountSetup();

      expect(session.isAccountSetupPending, isFalse);
      expect(session.isAuthenticated, isTrue);
      expect(notifications, 2);
      expect(storage.operations.last, 'saveAccountSetupPending(false)');
      expect(storage.storedAccountSetupPending, isTrue);

      gate.complete();
      await complete;

      expect(storage.storedAccountSetupPending, isFalse);
      expect(session.tokens, _tokens);
      expect(notifications, 2);
    });

    test(
      'a failed flag write is not thrown and setup stays complete',
      () async {
        await session.signIn(_tokens, isAccountSetupPending: true);
        storage.failFlagWrites = true;

        await expectLater(session.completeAccountSetup(), completes);

        expect(session.isAccountSetupPending, isFalse);
        expect(session.isAuthenticated, isTrue);
        expect(notifications, 2);
      },
    );

    test('a second call while persisting is a no-op', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);
      final Completer<void> gate = Completer<void>();
      storage.flagGate = gate.future;
      final int savesBefore = storage.flagSaveCount;

      final Future<void> first = session.completeAccountSetup();
      await session.completeAccountSetup();
      gate.complete();
      await first;

      expect(storage.flagSaveCount, savesBefore + 1);
      expect(notifications, 2);
    });
  });

  group('signOut', () {
    test('clears storage and the session and notifies once', () async {
      await session.signIn(_tokens);

      await session.signOut();

      expect(storage.clearCount, 1);
      expect(storage.storedTokens, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(notifications, 2);
    });

    test('clears the session even when storage fails, then rethrows', () async {
      await session.signIn(_tokens);
      storage.failClears = true;

      await expectLater(session.signOut(), throwsA(isA<StorageException>()));

      expect(session.isAuthenticated, isFalse);
      expect(session.tokens, isNull);
      expect(notifications, 2);
    });

    test('signs out in memory before the storage clear completes', () async {
      await session.signIn(_tokens);
      final Completer<void> gate = Completer<void>();
      storage.clearGate = gate.future;

      final Future<void> signOut = session.signOut();

      expect(session.isAuthenticated, isFalse);
      expect(notifications, 2);
      expect(storage.storedTokens, _tokens);

      gate.complete();
      await signOut;

      expect(storage.storedTokens, isNull);
      expect(notifications, 2);
    });

    test('a second signOut while the first is clearing is a no-op', () async {
      await session.signIn(_tokens);
      final Completer<void> gate = Completer<void>();
      storage.clearGate = gate.future;

      final Future<void> first = session.signOut();
      await session.signOut();
      gate.complete();
      await first;

      expect(storage.clearCount, 1);
      expect(notifications, 2);
    });

    test('clears the pending flag in memory', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);

      await session.signOut();

      expect(session.isAccountSetupPending, isFalse);
      expect(storage.storedAccountSetupPending, isFalse);
      expect(notifications, 2);
    });

    test('clears the pending flag in memory even when storage fails', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);
      storage.failClears = true;

      await expectLater(session.signOut(), throwsA(isA<StorageException>()));

      expect(session.isAccountSetupPending, isFalse);
    });

    test('a later sign-in without the flag is not pending', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);
      await session.signOut();

      await session.signIn(_tokens);

      expect(session.isAccountSetupPending, isFalse);
    });

    test('is a no-op when already signed out', () async {
      await session.signOut();

      expect(storage.clearCount, 0);
      expect(notifications, 0);
    });
  });
}
