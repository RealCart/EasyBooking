import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/data/repository/properties_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';

import '../../../../helpers/fake_properties_repository.dart';

const Failure _failure = StorageFailure(message: 'disk');

final class _FakePropertiesMockLocal implements PropertiesMockLocal {
  Either<Failure, List<PropertyEntity>> propertiesResult =
      Right<Failure, List<PropertyEntity>>(testProperties());
  final List<({String propertyId, bool isFavorite})> favoriteCalls =
      <({String propertyId, bool isFavorite})>[];

  @override
  Future<Either<Failure, List<PropertyEntity>>> loadProperties() async {
    return propertiesResult;
  }

  @override
  Future<Either<Failure, void>> setFavorite({
    required String propertyId,
    required bool isFavorite,
  }) async {
    favoriteCalls.add((propertyId: propertyId, isFavorite: isFavorite));
    return const Left<Failure, void>(_failure);
  }
}

void main() {
  group('PropertiesRepositoryImpl', () {
    late _FakePropertiesMockLocal local;
    late PropertiesRepositoryImpl repository;

    setUp(() {
      local = _FakePropertiesMockLocal();
      repository = PropertiesRepositoryImpl(local: local);
    });

    test('getProperty picks the property from the list', () async {
      expect(
        await repository.getProperty('p2'),
        Right<Failure, PropertyEntity>(testProperties()[1]),
      );
    });

    test('getProperty of an unknown id is a 404', () async {
      final Either<Failure, PropertyEntity> result = await repository
          .getProperty('missing');

      expect(
        result.fold((Failure failure) => failure, (_) => null),
        isA<ServerFailure>().having(
          (ServerFailure failure) => failure.statusCode,
          'statusCode',
          404,
        ),
      );
    });

    test('a list failure passes through both reads unchanged', () async {
      local.propertiesResult = const Left<Failure, List<PropertyEntity>>(
        _failure,
      );

      expect(
        await repository.getProperties(),
        const Left<Failure, List<PropertyEntity>>(_failure),
      );
      expect(
        await repository.getProperty('p1'),
        const Left<Failure, PropertyEntity>(_failure),
      );
    });

    test('setFavorite forwards both values and the failure', () async {
      final Either<Failure, void> result = await repository.setFavorite(
        propertyId: 'p2',
        isFavorite: true,
      );

      expect(local.favoriteCalls.single, (propertyId: 'p2', isFavorite: true));
      expect(result, const Left<Failure, void>(_failure));
    });
  });
}
