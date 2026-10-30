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

    test('is a no-op when already signed out', () async {
      await session.signOut();

      expect(storage.clearCount, 0);
      expect(notifications, 0);
    });
  });
}
