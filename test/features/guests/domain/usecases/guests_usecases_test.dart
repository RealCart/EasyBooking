import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/create_guest_contract_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_directory_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';

import '../../../../helpers/fake_guests_repository.dart';

const Failure _failure = ServerFailure(statusCode: 500, code: 'boom');

void main() {
  late FakeGuestsRepository repository;

  setUp(() => repository = FakeGuestsRepository());

  group('GetGuestDirectoryUsecase', () {
    test('forwards the trimmed query and returns the directory', () async {
      final Either<Failure, GuestDirectoryEntity> result =
          await GetGuestDirectoryUsecase(
            repository,
          )(const GetGuestDirectoryParamsEntity(query: '  Айжан  '));

      expect(repository.directoryQueries, <String>['Айжан']);
      expect(
        result,
        Right<Failure, GuestDirectoryEntity>(testGuestDirectory()),
      );
    });

    test('a blank query asks for the default view', () async {
      await GetGuestDirectoryUsecase(
        repository,
      )(const GetGuestDirectoryParamsEntity(query: ' \t '));
      await GetGuestDirectoryUsecase(
        repository,
      )(const GetGuestDirectoryParamsEntity());

      expect(repository.directoryQueries, <String>['', '']);
    });

    test('passes a failure through unchanged', () async {
      repository.directoryResult = const Left<Failure, GuestDirectoryEntity>(
        _failure,
      );

      final Either<Failure, GuestDirectoryEntity> result =
          await GetGuestDirectoryUsecase(
            repository,
          )(const GetGuestDirectoryParamsEntity(query: 'x'));

      expect(result, const Left<Failure, GuestDirectoryEntity>(_failure));
    });
  });

  group('GetGuestUsecase', () {
    test('forwards the guest id and returns the guest', () async {
      final Either<Failure, GuestEntity> result = await GetGuestUsecase(
        repository,
      )(const GetGuestParamsEntity(guestId: 'g1'));

      expect(repository.guestIds, <String>['g1']);
      expect(result, Right<Failure, GuestEntity>(testGuest()));
    });

    test('passes a failure through unchanged', () async {
      repository.guestResult = const Left<Failure, GuestEntity>(_failure);

      final Either<Failure, GuestEntity> result = await GetGuestUsecase(
        repository,
      )(const GetGuestParamsEntity(guestId: 'g1'));

      expect(result, const Left<Failure, GuestEntity>(_failure));
    });
  });

  group('CreateGuestContractUsecase', () {
    test('forwards the guest id and returns the contract id', () async {
      final Either<Failure, String> result = await CreateGuestContractUsecase(
        repository,
      )(const CreateGuestContractParamsEntity(guestId: 'g1'));

      expect(repository.createContractIds, <String>['g1']);
      expect(result, const Right<Failure, String>('draft-g1'));
    });

    test('passes a failure through unchanged', () async {
      repository.createContractResult = const Left<Failure, String>(_failure);

      final Either<Failure, String> result = await CreateGuestContractUsecase(
        repository,
      )(const CreateGuestContractParamsEntity(guestId: 'g1'));

      expect(result, const Left<Failure, String>(_failure));
    });
  });
}
