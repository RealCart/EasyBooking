import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';

import '../../../../../helpers/fake_auth_repository.dart';

const AccountSetupState _filled = AccountSetupState(
  firstName: ' Айгерим ',
  lastName: 'Садыкова',
  email: 'aigerim@example.kz',
  teamName: 'Esentai Stay',
  city: KazakhstanCities.almaty,
);

const Failure _serverFailure = ServerFailure(statusCode: 500);

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

  Future<void> fill() async {
    bloc
      ..add(AccountFirstNameChanged(_filled.firstName))
      ..add(AccountLastNameChanged(_filled.lastName))
      ..add(AccountEmailChanged(_filled.email))
      ..add(AccountTeamNameChanged(_filled.teamName))
      ..add(const AccountCitySelected(KazakhstanCities.almaty));
    await pumpEventQueue();
    states.clear();
  }

  Future<void> submitWith(Either<Failure, void> result) async {
    repository.createAccountResult = result;
    bloc.add(const AccountSetupSubmitted());
    await pumpEventQueue();
  }

  test('starts with an empty form', () {
    expect(bloc.state, const AccountSetupState());
    expect(bloc.state.fieldErrors, isEmpty);
  });

  group('field changes', () {
    test('each event updates its field', () async {
      await fill();

      expect(bloc.state, _filled);
    });

    test('an unchanged value emits nothing', () async {
      await fill();

      bloc
        ..add(AccountFirstNameChanged(_filled.firstName))
        ..add(const AccountCitySelected(KazakhstanCities.almaty));
      await pumpEventQueue();

      expect(states, isEmpty);
    });

    test('a change clears only that field error and the failure', () async {
      await submitWith(
        const Left<Failure, void>(
          ValidationFailure(
            fieldErrors: <String, String>{
              AccountFields.email: 'taken',
              AccountFields.teamName: 'too long',
              'timeZone': 'unknown',
            },
          ),
        ),
      );
      // The form was empty, so local validation failed first.
      expect(bloc.state.fieldErrors, hasLength(5));

      bloc.add(const AccountEmailChanged('a@b.kz'));
      await pumpEventQueue();

      expect(bloc.state.fieldErrors, <String, String>{
        AccountFields.firstName: AuthErrorCodes.required,
        AccountFields.lastName: AuthErrorCodes.required,
        AccountFields.teamName: AuthErrorCodes.required,
        AccountFields.city: AuthErrorCodes.required,
      });
      expect(bloc.state.status, RequestStatus.initial);
      expect(bloc.state.failure, isNull);
    });

    test('selecting a city clears the city error', () async {
      bloc.add(const AccountSetupSubmitted());
      await pumpEventQueue();
      expect(bloc.state.fieldErrors[AccountFields.city], isNotNull);

      bloc.add(const AccountCitySelected(KazakhstanCities.karaganda));
      await pumpEventQueue();

      expect(bloc.state.city, KazakhstanCities.karaganda);
      expect(bloc.state.fieldErrors, isNot(contains(AccountFields.city)));
      expect(bloc.state.fieldErrors, hasLength(4));
    });

    test('a change after a general failure clears it', () async {
      await fill();
      await submitWith(const Left<Failure, void>(_serverFailure));

      bloc.add(const AccountTeamNameChanged('Stay'));
      await pumpEventQueue();

      expect(states.last.failure, isNull);
      expect(states.last.status, RequestStatus.initial);
    });

    test('published field errors cannot be modified', () async {
      bloc.add(const AccountSetupSubmitted());
      await pumpEventQueue();
      bloc.add(const AccountFirstNameChanged('A'));
      await pumpEventQueue();

      expect(
        () => bloc.state.fieldErrors['x'] = 'y',
        throwsUnsupportedError,
      );
    });
  });

  group('AccountSetupSubmitted', () {
    test('emits loading, then success, with trimmed params', () async {
      await fill();

      await submitWith(voidSuccess);

      expect(states, <AccountSetupState>[
        _filled.copyWith(status: RequestStatus.loading),
        _filled.copyWith(status: RequestStatus.success),
      ]);
      expect(
        repository.createAccountCalls.single,
        const CreateAccountParams(
          firstName: 'Айгерим',
          lastName: 'Садыкова',
          email: 'aigerim@example.kz',
          teamName: 'Esentai Stay',
          city: KazakhstanCities.almaty,
        ),
      );
    });

    test('local validation errors go to fieldErrors', () async {
      bloc.add(const AccountEmailChanged('wrong'));
      await pumpEventQueue();
      states.clear();

      bloc.add(const AccountSetupSubmitted());
      await pumpEventQueue();

      expect(states, <AccountSetupState>[
        const AccountSetupState(email: 'wrong', status: RequestStatus.loading),
        const AccountSetupState(
          email: 'wrong',
          status: RequestStatus.failure,
          fieldErrors: <String, String>{
            AccountFields.firstName: AuthErrorCodes.required,
            AccountFields.lastName: AuthErrorCodes.required,
            AccountFields.email: AuthErrorCodes.invalidEmail,
            AccountFields.teamName: AuthErrorCodes.required,
            AccountFields.city: AuthErrorCodes.required,
          },
        ),
      ]);
      expect(repository.createAccountCalls, isEmpty);
    });

    test(
      'server field errors on shown fields go only to fieldErrors',
      () async {
        await fill();

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
      await fill();
      const ValidationFailure failure = ValidationFailure(
        fieldErrors: <String, String>{'timeZone': 'unknown'},
      );

      await submitWith(const Left<Failure, void>(failure));

      expect(bloc.state.status, RequestStatus.failure);
      expect(bloc.state.fieldErrors, <String, String>{'timeZone': 'unknown'});
      expect(bloc.state.failure, failure);
    });

    test('a ValidationFailure without field errors goes to failure', () async {
      await fill();
      const ValidationFailure failure = ValidationFailure(code: 'bad_input');

      await submitWith(const Left<Failure, void>(failure));

      expect(
        states.last,
        _filled.copyWith(
          status: RequestStatus.failure,
          failure: failure,
        ),
      );
    });

    test('any other failure goes to failure', () async {
      await fill();

      await submitWith(const Left<Failure, void>(_serverFailure));

      expect(states, <AccountSetupState>[
        _filled.copyWith(status: RequestStatus.loading),
        _filled.copyWith(
          status: RequestStatus.failure,
          failure: _serverFailure,
        ),
      ]);
    });

    test('a new submit clears previous field errors and failure', () async {
      await submitWith(voidSuccess);
      expect(bloc.state.fieldErrors, isNotEmpty);
      await fill();
      states.clear();

      await submitWith(const Left<Failure, void>(_serverFailure));
      await submitWith(voidSuccess);

      expect(states[2], _filled.copyWith(status: RequestStatus.loading));
      expect(states.last, _filled.copyWith(status: RequestStatus.success));
    });

    test('a submit while loading is dropped', () async {
      await fill();
      repository.holdCreateAccount = true;

      bloc
        ..add(const AccountSetupSubmitted())
        ..add(const AccountSetupSubmitted());
      await pumpEventQueue();
      bloc.add(const AccountSetupSubmitted());
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
      await fill();
      await submitWith(voidSuccess);

      bloc.add(const AccountSetupSubmitted());
      await pumpEventQueue();

      expect(repository.createAccountCalls, hasLength(1));
    });

    test('closing while creating emits nothing more', () async {
      await fill();
      repository.holdCreateAccount = true;
      bloc.add(const AccountSetupSubmitted());
      await pumpEventQueue();

      await bloc.close();
      repository.heldCreateAccounts.single.complete(voidSuccess);
      await pumpEventQueue();

      expect(states, <AccountSetupState>[
        _filled.copyWith(status: RequestStatus.loading),
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
      await fill();
      repository.holdCreateAccount = true;
      bloc.add(const AccountSetupSubmitted());
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
    test('reset flags win over supplied values', () {
      const AccountSetupState state = AccountSetupState(
        city: KazakhstanCities.almaty,
        failure: _serverFailure,
      );

      final AccountSetupState next = state.copyWith(
        city: KazakhstanCities.astana,
        resetCity: true,
        failure: _serverFailure,
        resetFailure: true,
      );

      expect(next.city, isNull);
      expect(next.failure, isNull);
    });

    test('keeps omitted fields', () {
      expect(_filled.copyWith(), _filled);
    });
  });
}
