import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/get_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';

import '../../../../helpers/fake_contracts_repository.dart';

const UpdateContractGuestParamsEntity _validGuest =
    UpdateContractGuestParamsEntity(
      contractId: 'c1',
      firstName: 'Данияр',
      lastName: 'Муратов',
      patronymic: 'Ерланович',
      iin: '960312300214',
      idNumber: '048216721',
    );

UpdateContractGuestParamsEntity _guest({
  String firstName = 'Данияр',
  String lastName = 'Муратов',
  String patronymic = 'Ерланович',
  String iin = '960312300214',
  String idNumber = '048216721',
}) {
  return UpdateContractGuestParamsEntity(
    contractId: 'c1',
    firstName: firstName,
    lastName: lastName,
    patronymic: patronymic,
    iin: iin,
    idNumber: idNumber,
  );
}

Map<String, String> _fieldErrorsOf(Either<Failure, ContractEntity> result) {
  return switch (result) {
    Left<Failure, ContractEntity>(value: final ValidationFailure failure) =>
      failure.fieldErrors,
    _ => throw TestFailure('Expected a ValidationFailure, got $result'),
  };
}

void main() {
  late FakeContractsRepository repository;

  setUp(() {
    repository = FakeContractsRepository();
  });

  group('GetContractUsecase', () {
    test('forwards the id and returns the contract', () async {
      final Either<Failure, ContractEntity> result = await GetContractUsecase(
        repository,
      )(const GetContractParamsEntity(contractId: 'c1'));

      expect(repository.getCalls, <String>['c1']);
      expect(result, Right<Failure, ContractEntity>(testContract()));
    });

    test('a repository failure passes through unchanged', () async {
      repository.getResult = const Left<Failure, ContractEntity>(
        ServerFailure(statusCode: 404),
      );

      expect(
        await GetContractUsecase(
          repository,
        )(const GetContractParamsEntity(contractId: 'missing')),
        const Left<Failure, ContractEntity>(ServerFailure(statusCode: 404)),
      );
    });
  });

  group('UpdateContractGuestUsecase', () {
    test('valid data is forwarded and the result returned', () async {
      repository.updateResult = Right<Failure, ContractEntity>(
        testSentContract(),
      );

      final Either<Failure, ContractEntity> result =
          await UpdateContractGuestUsecase(repository)(_validGuest);

      expect(repository.updateCalls, <UpdateContractGuestParamsEntity>[
        _validGuest,
      ]);
      expect(result, Right<Failure, ContractEntity>(testSentContract()));
    });

    test('trims names and removes spaces from the IIN and ID number', () async {
      await UpdateContractGuestUsecase(repository)(
        _guest(
          firstName: '  Данияр ',
          lastName: '\tМуратов  ',
          patronymic: '   ',
          iin: ' 960 312 300 214 ',
          idNumber: '048 216\t721',
        ),
      );

      expect(
        repository.updateCalls.single,
        _guest(patronymic: ''),
      );
    });

    test('blank names are required and nothing is saved', () async {
      final Either<Failure, ContractEntity> result =
          await UpdateContractGuestUsecase(
            repository,
          )(_guest(firstName: '  ', lastName: ''));

      expect(_fieldErrorsOf(result), <String, String>{
        ContractGuestFields.firstName: ContractErrorCodes.required,
        ContractGuestFields.lastName: ContractErrorCodes.required,
      });
      expect(repository.updateCalls, isEmpty);
    });

    test('an empty patronymic is allowed', () async {
      final Either<Failure, ContractEntity> result =
          await UpdateContractGuestUsecase(repository)(_guest(patronymic: ''));

      expect(result.isRight, isTrue);
      expect(repository.updateCalls.single.patronymic, '');
    });

    test('an empty IIN and ID number are required', () async {
      final Either<Failure, ContractEntity> result =
          await UpdateContractGuestUsecase(
            repository,
          )(_guest(iin: ' ', idNumber: ''));

      expect(_fieldErrorsOf(result), <String, String>{
        ContractGuestFields.iin: ContractErrorCodes.required,
        ContractGuestFields.idNumber: ContractErrorCodes.required,
      });
      expect(repository.updateCalls, isEmpty);
    });

    for (final String iin in <String>['96031230021', '9603123002145', 'abc']) {
      test('IIN "$iin" is invalid', () async {
        final Either<Failure, ContractEntity> result =
            await UpdateContractGuestUsecase(repository)(_guest(iin: iin));

        expect(_fieldErrorsOf(result), <String, String>{
          ContractGuestFields.iin: ContractErrorCodes.invalidIin,
        });
        expect(repository.updateCalls, isEmpty);
      });
    }

    for (final String idNumber in <String>[
      '04821672',
      '0482167210',
      '04821672x',
    ]) {
      test('ID number "$idNumber" is invalid', () async {
        final Either<Failure, ContractEntity> result =
            await UpdateContractGuestUsecase(
              repository,
            )(_guest(idNumber: idNumber));

        expect(_fieldErrorsOf(result), <String, String>{
          ContractGuestFields.idNumber: ContractErrorCodes.invalidIdNumber,
        });
        expect(repository.updateCalls, isEmpty);
      });
    }

    test(
      'reports every invalid field at once in an unmodifiable map',
      () async {
        final Either<Failure, ContractEntity> result =
            await UpdateContractGuestUsecase(repository)(
              _guest(firstName: '', iin: '123', idNumber: '1'),
            );

        final Map<String, String> errors = _fieldErrorsOf(result);
        expect(errors, <String, String>{
          ContractGuestFields.firstName: ContractErrorCodes.required,
          ContractGuestFields.iin: ContractErrorCodes.invalidIin,
          ContractGuestFields.idNumber: ContractErrorCodes.invalidIdNumber,
        });
        expect(() => errors['x'] = 'y', throwsUnsupportedError);
      },
    );

    test('a signed contract failure passes through unchanged', () async {
      repository.updateResult = const Left<Failure, ContractEntity>(
        ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );

      expect(
        await UpdateContractGuestUsecase(repository)(_validGuest),
        const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.alreadySigned),
        ),
      );
    });
  });

  group('SendContractUsecase', () {
    SendContractParamsEntity params(
      ContractDeliveryChannel channel,
      String address,
    ) {
      return SendContractParamsEntity(
        contractId: 'c1',
        channel: channel,
        address: address,
      );
    }

    test('an SMS phone in any format is sent as E.164', () async {
      final Either<Failure, ContractEntity> result = await SendContractUsecase(
        repository,
      )(params(ContractDeliveryChannel.sms, '8 (700) 318-45-21'));

      expect(
        repository.sendCalls.single,
        params(ContractDeliveryChannel.sms, '+77003184521'),
      );
      expect(result, Right<Failure, ContractEntity>(testSentContract()));
    });

    test('a WhatsApp national number is sent as E.164', () async {
      await SendContractUsecase(
        repository,
      )(params(ContractDeliveryChannel.whatsApp, '701 123 45 67'));

      expect(
        repository.sendCalls.single,
        params(ContractDeliveryChannel.whatsApp, '+77011234567'),
      );
    });

    test('an email is trimmed', () async {
      await SendContractUsecase(
        repository,
      )(params(ContractDeliveryChannel.email, '  guest@mail.kz '));

      expect(
        repository.sendCalls.single,
        params(ContractDeliveryChannel.email, 'guest@mail.kz'),
      );
    });

    for (final ContractDeliveryChannel channel in <ContractDeliveryChannel>[
      ContractDeliveryChannel.sms,
      ContractDeliveryChannel.whatsApp,
    ]) {
      test('an incomplete ${channel.name} phone is invalid_phone', () async {
        final Either<Failure, ContractEntity> result =
            await SendContractUsecase(repository)(params(channel, '700 318'));

        expect(
          result,
          const Left<Failure, ContractEntity>(
            ValidationFailure(code: ContractErrorCodes.invalidPhone),
          ),
        );
        expect(repository.sendCalls, isEmpty);
      });
    }

    test('a non-Kazakhstan phone is invalid_phone', () async {
      final Either<Failure, ContractEntity> result = await SendContractUsecase(
        repository,
      )(params(ContractDeliveryChannel.sms, '6001234567'));

      expect(
        result,
        const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.invalidPhone),
        ),
      );
      expect(repository.sendCalls, isEmpty);
    });

    for (final String email in <String>['', 'guest', 'guest@', '@mail.kz']) {
      test('email "$email" is invalid_email', () async {
        final Either<Failure, ContractEntity> result =
            await SendContractUsecase(
              repository,
            )(params(ContractDeliveryChannel.email, email));

        expect(
          result,
          const Left<Failure, ContractEntity>(
            ValidationFailure(code: ContractErrorCodes.invalidEmail),
          ),
        );
        expect(repository.sendCalls, isEmpty);
      });
    }

    test('a signed contract failure passes through unchanged', () async {
      repository.sendResult = const Left<Failure, ContractEntity>(
        ValidationFailure(code: ContractErrorCodes.alreadySigned),
      );

      expect(
        await SendContractUsecase(
          repository,
        )(params(ContractDeliveryChannel.sms, '+77003184521')),
        const Left<Failure, ContractEntity>(
          ValidationFailure(code: ContractErrorCodes.alreadySigned),
        ),
      );
    });
  });
}
