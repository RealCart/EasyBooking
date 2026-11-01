import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_property_settings_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

void main() {
  group('SavePropertySettingsUsecase', () {
    late FakePropertyManagementRepository repository;
    late SavePropertySettingsUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = SavePropertySettingsUsecase(repository);
    });

    test('forwards both values and returns the stored settings', () async {
      final Either<Failure, PropertySettingsEntity> result = await usecase(
        const SavePropertySettingsParamsEntity(
          propertyId: 'p2',
          acceptsBookings: false,
        ),
      );

      expect(repository.saveSettingsCalls.single, (
        propertyId: 'p2',
        acceptsBookings: false,
      ));
      expect(
        result,
        Right<Failure, PropertySettingsEntity>(
          testPropertySettings(acceptsBookings: false),
        ),
      );
    });

    test('passes a failure through unchanged', () async {
      repository.saveSettingsResult =
          const Left<Failure, PropertySettingsEntity>(
            StorageFailure(message: 'disk'),
          );

      expect(
        await usecase(
          const SavePropertySettingsParamsEntity(
            propertyId: 'p1',
            acceptsBookings: true,
          ),
        ),
        const Left<Failure, PropertySettingsEntity>(
          StorageFailure(message: 'disk'),
        ),
      );
    });
  });
}
