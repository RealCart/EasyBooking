import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

void main() {
  group('GetPropertyBookingsUsecase', () {
    late FakePropertyManagementRepository repository;
    late GetPropertyBookingsUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = GetPropertyBookingsUsecase(repository);
    });

    test('forwards the property id and returns the bookings', () async {
      final Either<Failure, PropertyBookingsEntity> result = await usecase(
        const GetPropertyParamsEntity(propertyId: 'p1'),
      );

      expect(repository.bookingsIds, <String>['p1']);
      expect(
        result,
        Right<Failure, PropertyBookingsEntity>(testPropertyBookings()),
      );
    });

    test('passes a failure through unchanged', () async {
      repository.bookingsResult = const Left<Failure, PropertyBookingsEntity>(
        ServerFailure(statusCode: 404),
      );

      expect(
        await usecase(const GetPropertyParamsEntity(propertyId: 'missing')),
        const Left<Failure, PropertyBookingsEntity>(
          ServerFailure(statusCode: 404),
        ),
      );
    });
  });
}
