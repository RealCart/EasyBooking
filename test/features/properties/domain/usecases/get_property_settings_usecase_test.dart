import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

void main() {
  group('GetPropertySettingsUsecase', () {
    late FakePropertyManagementRepository repository;
    late GetPropertySettingsUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = GetPropertySettingsUsecase(repository);
    });

    test('forwards the property id and returns the settings', () async {
      final Either<Failure, PropertySettingsEntity> result = await usecase(
        const GetPropertyParamsEntity(propertyId: 'p1'),
      );

      expect(repository.settingsIds, <String>['p1']);
      expect(
        result,
        Right<Failure, PropertySettingsEntity>(testPropertySettings()),
      );
    });

    test('passes a failure through unchanged', () async {
      repository.settingsResult = const Left<Failure, PropertySettingsEntity>(
        ConnectionFailure(),
      );

      expect(
        await usecase(const GetPropertyParamsEntity(propertyId: 'p1')),
        const Left<Failure, PropertySettingsEntity>(ConnectionFailure()),
      );
    });
  });
}
