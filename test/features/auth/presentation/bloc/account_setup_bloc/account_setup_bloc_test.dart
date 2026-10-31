import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

const CreateAccountParamsEntity _params = CreateAccountParamsEntity(
  firstName: ' Айгерим ',
  lastName: 'Садыкова',
  email: 'aigerim@example.kz',
  teamName: 'Esentai Stay',
  city: KazakhstanCities.almaty,
);

const Failure _serverFailure = ServerFailure(statusCode: 500);

const ValidationFailure _serverFieldErrors = ValidationFailure(
  fieldErrors: <String, String>{
    AccountFields.email: 'taken',
    AccountFields.teamName: 'too long',
    'timeZone': 'unknown',
  },
);

void main() {
  late FakeAuthRepository repository;
  late AccountSetupBloc bloc;
  late List<AccountSetupState> states;

  setUp(() {
    repository = FakeAuthRepository();
    bloc = AccountSetupBloc(
      createAccount: CreateAccountUsecase(repository),
      signOut: SignOutUsecase(repository),
    );
    states = <AccountSetupState>[];
    final StreamSubscription<AccountSetupState> subscription = bloc.stream
        .listen(states.add);
    addTearDown(() async {
      await subscription.cancel();
      await bloc.close();
    });
  });

  Future<void> submitWith(
    Either<Failure, void> result, {
    CreateAccountParamsEntity params = _params,
  }) async {
    repository.createAccountResult = result;
    bloc.add(AccountSetupSubmitted(params));
    await pumpEventQueue();
  }

  test('starts idle without errors', () {
    expect(bloc.state, const AccountSetupState());
    expect(bloc.state.fieldErrors, isEmpty);
  });

  group('AccountFieldEdited', () {
    test('clears only that field error and the failure', () async {
      await submitWith(const Left<Failure, void>(_serverFieldErrors));
      expect(bloc.state.fieldErrors, hasLength(3));

      bloc.add(const AccountFieldEdited(AccountFields.email));
      await pumpEventQueue();

      expect(bloc.state.fieldErrors, <String, String>{
        AccountFields.teamName: 'too long',
        'timeZone': 'unknown',
      });
      expect(bloc.state.status, RequestStatus.initial);
      expect(bloc.state.failure, isNull);
    });

    test('an edit after a general failure clears it', () async {
      await submitWith(const Left<Failure, void>(_serverFailure));

      bloc.add(const AccountFieldEdited(AccountFields.teamName));
      await pumpEventQueue();

      expect(states.last, const AccountSetupState());
    });

    test('an edit without errors emits nothing', () async {
      bloc.add(const AccountFieldEdited(AccountFields.firstName));
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test('published field errors cannot be modified', () async {
      await submitWith(const Left<Failure, void>(_serverFieldErrors));
      bloc.add(const AccountFieldEdited(AccountFields.email));
      await pumpEventQueue();

      expect(
        () => bloc.state.fieldErrors['x'] = 'y',
        throwsUnsupportedError,
      );
    });
  });

  group('AccountSetupSubmitted', () {
    test('emits loading, then success, with trimmed params', () async {
      await submitWith(voidSuccess);

      expect(states, const <AccountSetupState>[
        AccountSetupState(status: RequestStatus.loading),
        AccountSetupState(status: RequestStatus.success),
      ]);
      expect(
        repository.createAccountCalls.single,
        const CreateAccountParamsEntity(
          firstName: 'Айгерим',
          lastName: 'Садыкова',
          email: 'aigerim@example.kz',
          teamName: 'Esentai Stay',
          city: KazakhstanCities.almaty,
        ),
      );
    });

    test('use-case validation errors go to fieldErrors', () async {
      await submitWith(
        voidSuccess,
        params: const CreateAccountParamsEntity(
          firstName: '',
          lastName: '',
          email: 'wrong',
          teamName: '',
          city: KazakhstanCities.almaty,
        ),
      );

      expect(states, const <AccountSetupState>[
        AccountSetupState(status: RequestStatus.loading),
        AccountSetupState(
          status: RequestStatus.failure,
          fieldErrors: <String, String>{
            AccountFields.firstName: AuthErrorCodes.required,
            AccountFields.lastName: AuthErrorCodes.required,
            AccountFields.email: AuthErrorCodes.invalidEmail,
            AccountFields.teamName: AuthErrorCodes.required,
          },
        ),
      ]);
      expect(repository.createAccountCalls, isEmpty);
    });

    test(
      'server field errors on shown fields go only to fieldErrors',
      () async {
        await submitWith(
          const Left<Failure, void>(
            ValidationFailure(
              fieldErrors: <String, String>{
                AccountFields.email: 'taken',
                'timeZone': 'unknown',
              },
            ),
          ),
        );

        expect(bloc.state.status, RequestStatus.failure);
        expect(bloc.state.fieldErrors, <String, String>{
          AccountFields.email: 'taken',
          'timeZone': 'unknown',
        });
        expect(bloc.state.failure, isNull);
      },
    );

    test('field errors only on unknown keys also set failure', () async {
      const ValidationFailure failure = ValidationFailure(
        fieldErrors: <String, String>{'timeZone': 'unknown'},
      );

      await submitWith(const Left<Failure, void>(failure));

      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.fieldErrors, <String, String>{'timeZone': 'unknown'});
      expect(bloc.state.failure, failure);
    });

    test('a ValidationFailure without field errors goes to failure', () async {
      const ValidationFailure failure = ValidationFailure(code: 'bad_input');

      await submitWith(const Left<Failure, void>(failure));

      expect(
        states.last,
        const AccountSetupState(
          status: RequestStatus.failure,
          failure: failure,
        ),
      );
    });

    test('any other failure goes to failure', () async {
      await submitWith(const Left<Failure, void>(_serverFailure));

      expect(states, const <AccountSetupState>[
        AccountSetupState(status: RequestStatus.loading),
        AccountSetupState(
          status: RequestStatus.failure,
          failure: _serverFailure,
        ),
      ]);
    });

    test('a new submit clears previous field errors and failure', () async {
      await submitWith(const Left<Failure, void>(_serverFieldErrors));
      states.clear();

      await submitWith(voidSuccess);

      expect(states, const <AccountSetupState>[
        AccountSetupState(status: RequestStatus.loading),
        AccountSetupState(status: RequestStatus.success),
      ]);
    });

    test('a submit while loading is dropped', () async {
      repository.holdCreateAccount = true;

      bloc
        ..add(const AccountSetupSubmitted(_params))
        ..add(const AccountSetupSubmitted(_params));
      await pumpEventQueue();
      bloc.add(const AccountSetupSubmitted(_params));
      await pumpEventQueue();

      expect(repository.createAccountCalls, hasLength(1));

      repository.heldCreateAccounts.single.complete(voidSuccess);
      await pumpEventQueue();

      expect(states.map((AccountSetupState s) => s.status), <RequestStatus>[
        RequestStatus.loading,
        RequestStatus.success,
      ]);
    });

    test('a submit after success is ignored', () async {
      await submitWith(voidSuccess);

      bloc.add(const AccountSetupSubmitted(_params));
      await pumpEventQueue();

      expect(repository.createAccountCalls, hasLength(1));
    });

    test('closing while creating emits nothing more', () async {
      repository.holdCreateAccount = true;
      bloc.add(const AccountSetupSubmitted(_params));
      await pumpEventQueue();

      await bloc.close();
      repository.heldCreateAccounts.single.complete(voidSuccess);
      await pumpEventQueue();

      expect(states, const <AccountSetupState>[
        AccountSetupState(status: RequestStatus.loading),
      ]);
    });
  });

  group('AccountSetupCancelled', () {
    test('signs out and emits nothing on success', () async {
      bloc.add(const AccountSetupCancelled());
      await pumpEventQueue();

      expect(repository.signOutCount, 1);
      expect(states, isEmpty);
    });

    test('surfaces a sign-out failure', () async {
      const Failure failure = StorageFailure(message: 'clear failed');
      repository.signOutResult = const Left<Failure, void>(failure);

      bloc.add(const AccountSetupCancelled());
      await pumpEventQueue();

      expect(states, <AccountSetupState>[
        const AccountSetupState(
          status: RequestStatus.failure,
          failure: failure,
        ),
      ]);
    });

    test('is ignored while the account is being created', () async {
      repository.holdCreateAccount = true;
      bloc.add(const AccountSetupSubmitted(_params));
      await pumpEventQueue();

      bloc.add(const AccountSetupCancelled());
      await pumpEventQueue();

      expect(repository.signOutCount, 0);

      repository.heldCreateAccounts.single.complete(voidSuccess);
      await pumpEventQueue();
      bloc.add(const AccountSetupCancelled());
      await pumpEventQueue();

      expect(repository.signOutCount, 1);
    });

    test('a second cancel while signing out is dropped', () async {
      repository.holdSignOut = true;

      bloc
        ..add(const AccountSetupCancelled())
        ..add(const AccountSetupCancelled());
      await pumpEventQueue();

      expect(repository.signOutCount, 1);
      repository.heldSignOuts.single.complete(voidSuccess);
      await pumpEventQueue();
    });

    test('closing while signing out emits nothing', () async {
      repository
        ..holdSignOut = true
        ..signOutResult = const Left<Failure, void>(_serverFailure);
      bloc.add(const AccountSetupCancelled());
      await pumpEventQueue();

      await bloc.close();
      repository.heldSignOuts.single.complete(
        const Left<Failure, void>(_serverFailure),
      );
      await pumpEventQueue();

      expect(states, isEmpty);
    });
  });

  group('AccountSetupState.copyWith', () {
    test('the reset flag wins over a supplied failure', () {
      const AccountSetupState state = AccountSetupState(
        failure: _serverFailure,
      );

      expect(
        state.copyWith(failure: _serverFailure, resetFailure: true).failure,
        isNull,
      );
    });

    test('keeps omitted fields', () {
      const AccountSetupState state = AccountSetupState(
        status: RequestStatus.failure,
        failure: _serverFailure,
        fieldErrors: <String, String>{AccountFields.email: 'taken'},
      );

      expect(state.copyWith(), state);
    });
  });
}
