import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/data/repository/guests_repository_impl.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_directory_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';

import '../../../../helpers/fake_guests_repository.dart';

const Failure _failure = ServerFailure(statusCode: 404, message: 'missing');

void main() {
  late FakeGuestsMockLocal local;
  late GuestsRepositoryImpl repository;

  setUp(() {
    local = FakeGuestsMockLocal();
    repository = GuestsRepositoryImpl(local: local);
  });

  group('GuestsRepositoryImpl', () {
    test(
      'getDirectory forwards the query and returns the source result',
      () async {
        final Either<Failure, GuestDirectoryEntity> result = await repository
            .getDirectory('samal');

        expect(local.directoryQueries, <String>['samal']);
        expect(
          result,
          Right<Failure, GuestDirectoryEntity>(testGuestDirectory()),
        );
      },
    );

    test('getGuest forwards the id and returns the source result', () async {
      final Either<Failure, GuestEntity> result = await repository.getGuest(
        'g1',
      );

      expect(local.guestIds, <String>['g1']);
      expect(result, Right<Failure, GuestEntity>(testGuest()));
    });

    test(
      'createContract forwards the guest id and returns the draft id',
      () async {
        final Either<Failure, String> result = await repository.createContract(
          'g1',
        );

        expect(local.createContractIds, <String>['g1']);
        expect(result, const Right<Failure, String>('draft-g1'));
      },
    );

    test('typed failures pass through unchanged', () async {
      local
        ..directoryResult = const Left<Failure, GuestDirectoryEntity>(_failure)
        ..guestResult = const Left<Failure, GuestEntity>(_failure)
        ..createContractResult = const Left<Failure, String>(_failure);

      final Either<Failure, GuestDirectoryEntity> directory = await repository
          .getDirectory('');
      final Either<Failure, GuestEntity> guest = await repository.getGuest(
        'x',
      );
      final Either<Failure, String> contract = await repository.createContract(
        'x',
      );

      expect(directory, const Left<Failure, GuestDirectoryEntity>(_failure));
      expect(guest, const Left<Failure, GuestEntity>(_failure));
      expect(contract, const Left<Failure, String>(_failure));
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getDirectory(''), throwsStateError);
      await expectLater(repository.getGuest('g1'), throwsStateError);
      await expectLater(repository.createContract('g1'), throwsStateError);
    });
  });
}
