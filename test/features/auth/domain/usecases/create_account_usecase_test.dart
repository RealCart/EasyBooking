import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';

import '../../../../helpers/fake_auth_repository.dart';

CreateAccountParams _params({
  String firstName = 'Айгерим',
  String lastName = 'Садыкова',
  String email = 'aigerim@example.kz',
  String teamName = 'Esentai Stay',
  CityEntity? city = KazakhstanCities.almaty,
}) {
  return CreateAccountParams(
    firstName: firstName,
    lastName: lastName,
    email: email,
    teamName: teamName,
    city: city,
  );
}

Map<String, String> _fieldErrorsOf(Either<Failure, void> result) {
  return switch (result) {
    Left<Failure, void>(value: final ValidationFailure failure) =>
      failure.fieldErrors,
    _ => throw TestFailure('Expected a ValidationFailure, got $result'),
  };
}

void main() {
  late FakeAuthRepository repository;
  late CreateAccountUsecase usecase;

  setUp(() {
    repository = FakeAuthRepository();
    usecase = CreateAccountUsecase(repository);
  });

  group('CreateAccountUsecase', () {
    test('passes trimmed params with the city to the repository', () async {
      final Either<Failure, void> result = await usecase(
        _params(
          firstName: '  Айгерим ',
          lastName: '\tСадыкова\n',
          email: ' aigerim@example.kz  ',
          teamName: '  Esentai Stay  ',
          city: KazakhstanCities.shymkent,
        ),
      );

      expect(result.isRight, isTrue);
      expect(repository.createAccountCalls, <CreateAccountParams>[
        _params(city: KazakhstanCities.shymkent),
      ]);
    });

    test('preserves a repository failure', () async {
      const Failure failure = ValidationFailure(
        fieldErrors: <String, String>{AccountFields.email: 'taken'},
      );
      repository.createAccountResult = const Left<Failure, void>(failure);

      expect(await usecase(_params()), const Left<Failure, void>(failure));
    });

    test('reports every invalid field in one failure', () async {
      final Either<Failure, void> result = await usecase(
        const CreateAccountParams(
          firstName: '',
          lastName: '   ',
          email: 'not-an-email',
          teamName: '\n',
          city: null,
        ),
      );

      expect(_fieldErrorsOf(result), <String, String>{
        AccountFields.firstName: AuthErrorCodes.required,
        AccountFields.lastName: AuthErrorCodes.required,
        AccountFields.email: AuthErrorCodes.invalidEmail,
        AccountFields.teamName: AuthErrorCodes.required,
        AccountFields.city: AuthErrorCodes.required,
      });
      expect(
        result,
        isA<Left<Failure, void>>().having(
          (Left<Failure, void> left) => (left.value as ValidationFailure).code,
          'code',
          isNull,
        ),
      );
      expect(repository.createAccountCalls, isEmpty);
    });

    test('a blank email is required rather than invalid', () async {
      expect(
        _fieldErrorsOf(await usecase(_params(email: '  '))),
        <String, String>{AccountFields.email: AuthErrorCodes.required},
      );
    });

    test('a missing city alone is reported as required', () async {
      expect(
        _fieldErrorsOf(await usecase(_params(city: null))),
        <String, String>{AccountFields.city: AuthErrorCodes.required},
      );
      expect(repository.createAccountCalls, isEmpty);
    });

    test('rejects malformed emails', () async {
      for (final String email in <String>[
        'aigerim',
        'aigerim@',
        '@example.kz',
        'aigerim@example',
        'ai gerim@example.kz',
      ]) {
        expect(
          _fieldErrorsOf(await usecase(_params(email: email))),
          <String, String>{AccountFields.email: AuthErrorCodes.invalidEmail},
          reason: email,
        );
      }
      expect(repository.createAccountCalls, isEmpty);
    });

    test('the field errors map cannot be modified', () async {
      final Map<String, String> fieldErrors = _fieldErrorsOf(
        await usecase(_params(firstName: '')),
      );

      expect(() => fieldErrors['x'] = 'y', throwsUnsupportedError);
    });
  });
}
