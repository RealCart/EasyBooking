import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/publish_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

PublishPropertyParamsEntity _params({
  int pricePerNight = 42500,
  int deposit = 50000,
  Duration checkInTime = const Duration(hours: 14),
  Duration checkOutTime = const Duration(hours: 12),
  int minNights = 2,
  int cleaningFee = 8000,
}) {
  return PublishPropertyParamsEntity(
    terms: PropertyTermsEntity(
      pricePerNight: pricePerNight,
      deposit: deposit,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      minNights: minNights,
      cleaningFee: cleaningFee,
    ),
  );
}

void main() {
  group('PublishPropertyUsecase', () {
    late FakePropertyManagementRepository repository;
    late PublishPropertyUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = PublishPropertyUsecase(repository);
    });

    Future<Map<String, String>> fieldErrors(
      PublishPropertyParamsEntity params,
    ) async {
      final Either<Failure, String> result = await usecase(params);
      return result.fold(
        (Failure failure) => (failure as ValidationFailure).fieldErrors,
        (_) => fail('Expected a ValidationFailure'),
      );
    }

    test('publishes valid terms and returns the new id', () async {
      final Either<Failure, String> result = await usecase(_params());

      expect(result, const Right<Failure, String>('new-property-1'));
      expect(repository.publishedTerms.single, testTerms);
    });

    test('accepts the edges: 1 ₸, no deposit or cleaning, 1 and 30 nights, '
        '00:00 and 23:59', () async {
      final List<PublishPropertyParamsEntity> edges =
          <PublishPropertyParamsEntity>[
            _params(pricePerNight: 1, deposit: 0, cleaningFee: 0),
            _params(minNights: 1),
            _params(minNights: 30),
            _params(
              checkInTime: Duration.zero,
              checkOutTime: const Duration(hours: 23, minutes: 59),
            ),
          ];
      for (final PublishPropertyParamsEntity params in edges) {
        expect((await usecase(params)).isRight, isTrue, reason: '$params');
      }
      expect(repository.publishedTerms, hasLength(edges.length));
    });

    final Map<String, (PublishPropertyParamsEntity, String)> invalid =
        <String, (PublishPropertyParamsEntity, String)>{
          'a zero price': (
            _params(pricePerNight: 0),
            AddPropertyFields.pricePerNight,
          ),
          'a negative deposit': (
            _params(deposit: -1),
            AddPropertyFields.deposit,
          ),
          'a negative cleaning fee': (
            _params(cleaningFee: -1),
            AddPropertyFields.cleaningFee,
          ),
          'zero minimum nights': (
            _params(minNights: 0),
            AddPropertyFields.minNights,
          ),
          '31 minimum nights': (
            _params(minNights: 31),
            AddPropertyFields.minNights,
          ),
          'a check-in of 24:00': (
            _params(checkInTime: const Duration(hours: 24)),
            AddPropertyFields.checkInTime,
          ),
          'a negative check-in': (
            _params(checkInTime: const Duration(minutes: -1)),
            AddPropertyFields.checkInTime,
          ),
          'a check-out with seconds': (
            _params(checkOutTime: const Duration(hours: 12, seconds: 30)),
            AddPropertyFields.checkOutTime,
          ),
        };
    for (final MapEntry<String, (PublishPropertyParamsEntity, String)> entry
        in invalid.entries) {
      test('${entry.key} is out of range and nothing is published', () async {
        final (PublishPropertyParamsEntity params, String field) = entry.value;

        expect(await fieldErrors(params), <String, String>{
          field: PropertyErrorCodes.outOfRange,
        });
        expect(repository.publishedTerms, isEmpty);
      });
    }

    test('reports every invalid field at once', () async {
      expect(
        await fieldErrors(
          _params(
            pricePerNight: 0,
            deposit: -5,
            checkInTime: const Duration(hours: 25),
            checkOutTime: const Duration(days: 1),
            minNights: 99,
            cleaningFee: -5,
          ),
        ),
        <String, String>{
          AddPropertyFields.pricePerNight: PropertyErrorCodes.outOfRange,
          AddPropertyFields.deposit: PropertyErrorCodes.outOfRange,
          AddPropertyFields.checkInTime: PropertyErrorCodes.outOfRange,
          AddPropertyFields.checkOutTime: PropertyErrorCodes.outOfRange,
          AddPropertyFields.minNights: PropertyErrorCodes.outOfRange,
          AddPropertyFields.cleaningFee: PropertyErrorCodes.outOfRange,
        },
      );
    });

    test('passes draftIncomplete from the repository through', () async {
      repository.publishResult = const Left<Failure, String>(
        ValidationFailure(code: PropertyErrorCodes.draftIncomplete),
      );

      expect(
        await usecase(_params()),
        const Left<Failure, String>(
          ValidationFailure(code: PropertyErrorCodes.draftIncomplete),
        ),
      );
    });
  });
}
