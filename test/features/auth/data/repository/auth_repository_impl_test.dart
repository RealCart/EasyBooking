import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/data/repository/auth_repository_impl.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';

import '../../../../helpers/fake_auth_remote.dart';
import '../../../../helpers/fake_session_storage.dart';

const String _phone = '+77001234567';
const AuthTokens _tokens = AuthTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
);

const CreateAccountParamsEntity _params = CreateAccountParamsEntity(
  firstName: 'Айгерим',
  lastName: 'Садыкова',
  email: 'aigerim@example.kz',
  teamName: 'Esentai Stay',
  city: KazakhstanCities.kostanay,
);

void main() {
  late FakeAuthRemote remote;
  late FakeSessionStorage storage;
  late AuthSession session;
  late AuthRepositoryImpl repository;
  late int notifications;

  setUp(() {
    remote = FakeAuthRemote();
    storage = FakeSessionStorage();
    session = AuthSession(sessionStorage: storage);
    repository = AuthRepositoryImpl(remote: remote, session: session);
    notifications = 0;
    session.addListener(() => notifications++);
  });

  tearDown(() => session.dispose());

  group('AuthRepositoryImpl.sendCode', () {
    test('maps the model to an entity with the requested phone', () async {
      remote.resendAfterSeconds = 60;

      expect(
        await repository.sendCode(_phone),
        const Right<Failure, OtpChallengeEntity>(
          OtpChallengeEntity(
            phone: _phone,
            resendAfter: Duration(seconds: 60),
          ),
        ),
      );
      expect(remote.sentPhones, <String>[_phone]);
    });

    test('passes a remote failure through unchanged', () async {
      const Failure failure = ServerFailure(
        statusCode: 429,
        code: AuthErrorCodes.tooManyRequests,
      );
      remote.sendCodeFailure = failure;

      expect(
        await repository.sendCode(_phone),
        const Left<Failure, OtpChallengeEntity>(failure),
      );
    });

    test('lets an Error propagate as a programming defect', () async {
      remote.sendCodeError = StateError('bug');

      await expectLater(
        repository.sendCode(_phone),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AuthRepositoryImpl.verifyCode', () {
    test('a new user signs in with account setup pending', () async {
      remote.verifyResponse = const VerifyCodeResponseModel(
        accessToken: 'access',
        refreshToken: 'refresh',
        isNewUser: true,
      );

      final Either<Failure, void> result = await repository.verifyCode(
        phone: _phone,
        code: '482913',
      );

      expect(result.isRight, isTrue);
      expect(remote.verifyCalls, <({String phone, String code})>[
        (phone: _phone, code: '482913'),
      ]);
      expect(session.tokens, _tokens);
      expect(session.isAccountSetupPending, isTrue);
      expect(storage.storedTokens, _tokens);
      expect(storage.storedAccountSetupPending, isTrue);
      expect(notifications, 1);
    });

    test('an existing user signs in without pending setup', () async {
      final Either<Failure, void> result = await repository.verifyCode(
        phone: _phone,
        code: '482913',
      );

      expect(result.isRight, isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(session.isAccountSetupPending, isFalse);
      expect(storage.storedAccountSetupPending, isFalse);
    });

    test('a remote failure leaves the session untouched', () async {
      remote.verifyCodeFailure = const ValidationFailure(
        code: AuthErrorCodes.invalidCode,
      );

      expect(
        await repository.verifyCode(phone: _phone, code: '000000'),
        const Left<Failure, void>(
          ValidationFailure(code: AuthErrorCodes.invalidCode),
        ),
      );
      expect(session.isAuthenticated, isFalse);
      expect(storage.operations, isEmpty);
      expect(notifications, 0);
    });

    test('a 429 is preserved as a ServerFailure', () async {
      remote.verifyCodeFailure = const ServerFailure(
        statusCode: 429,
        code: AuthErrorCodes.tooManyRequests,
      );

      expect(
        await repository.verifyCode(phone: _phone, code: '000000'),
        const Left<Failure, void>(
          ServerFailure(statusCode: 429, code: AuthErrorCodes.tooManyRequests),
        ),
      );
      expect(session.isAuthenticated, isFalse);
    });

    test('a token write failure returns StorageFailure signed out', () async {
      storage.failWrites = true;

      expect(
        await repository.verifyCode(phone: _phone, code: '482913'),
        const Left<Failure, void>(StorageFailure(message: 'write failed')),
      );
      expect(session.isAuthenticated, isFalse);
      expect(notifications, 0);
    });

    test('a flag write failure returns StorageFailure signed out', () async {
      storage.failFlagWrites = true;
      remote.verifyResponse = const VerifyCodeResponseModel(
        accessToken: 'access',
        isNewUser: true,
      );

      expect(
        await repository.verifyCode(phone: _phone, code: '482913'),
        const Left<Failure, void>(
          StorageFailure(message: 'flag write failed'),
        ),
      );
      expect(session.isAuthenticated, isFalse);
      expect(storage.saveCount, 0);
    });
  });

  group('AuthRepositoryImpl.createAccount', () {
    setUp(() async {
      await session.signIn(_tokens, isAccountSetupPending: true);
      notifications = 0;
    });

    test('sends the request model and completes account setup', () async {
      final Either<Failure, void> result = await repository.createAccount(
        _params,
      );

      expect(result.isRight, isTrue);
      expect(remote.createAccountRequests.single.toJson(), <String, Object?>{
        'firstName': 'Айгерим',
        'lastName': 'Садыкова',
        'email': 'aigerim@example.kz',
        'teamName': 'Esentai Stay',
        'city': 'kostanay',
        'timeZone': 'Asia/Qostanay',
      });
      expect(session.isAccountSetupPending, isFalse);
      expect(session.isAuthenticated, isTrue);
      expect(storage.storedAccountSetupPending, isFalse);
      expect(notifications, 1);
    });

    test('a 422 keeps field errors and the pending setup', () async {
      remote.createAccountFailure = const ValidationFailure(
        fieldErrors: <String, String>{
          AccountFields.email: 'taken',
          AccountFields.teamName: 'too long',
        },
      );

      expect(
        await repository.createAccount(_params),
        const Left<Failure, void>(
          ValidationFailure(
            fieldErrors: <String, String>{
              AccountFields.email: 'taken',
              AccountFields.teamName: 'too long',
            },
          ),
        ),
      );
      expect(session.isAccountSetupPending, isTrue);
      expect(storage.storedAccountSetupPending, isTrue);
      expect(notifications, 0);
    });

    test('a 429 is preserved as a ServerFailure', () async {
      remote.createAccountFailure = const ServerFailure(statusCode: 429);

      expect(
        await repository.createAccount(_params),
        const Left<Failure, void>(ServerFailure(statusCode: 429)),
      );
      expect(session.isAccountSetupPending, isTrue);
    });

    test('a 401 is an UnauthorizedFailure', () async {
      remote.createAccountFailure = const UnauthorizedFailure();

      expect(
        await repository.createAccount(_params),
        const Left<Failure, void>(UnauthorizedFailure()),
      );
    });

    test('a failed flag write still completes setup', () async {
      storage.failFlagWrites = true;

      final Either<Failure, void> result = await repository.createAccount(
        _params,
      );

      expect(result.isRight, isTrue);
      expect(session.isAccountSetupPending, isFalse);
      expect(notifications, 1);
    });
  });

  group('AuthRepositoryImpl.signOut', () {
    test('signs out and clears the storage', () async {
      await session.signIn(_tokens, isAccountSetupPending: true);

      final Either<Failure, void> result = await repository.signOut();

      expect(result.isRight, isTrue);
      expect(session.isAuthenticated, isFalse);
      expect(session.isAccountSetupPending, isFalse);
      expect(storage.storedTokens, isNull);
      expect(storage.storedAccountSetupPending, isFalse);
    });

    test(
      'a clear failure is a StorageFailure but signs out in memory',
      () async {
        await session.signIn(_tokens);
        storage.failClears = true;

        expect(
          await repository.signOut(),
          const Left<Failure, void>(StorageFailure(message: 'clear failed')),
        );
        expect(session.isAuthenticated, isFalse);
      },
    );

    test('signed out already is a success without storage calls', () async {
      expect((await repository.signOut()).isRight, isTrue);
      expect(storage.clearCount, 0);
    });
  });
}
