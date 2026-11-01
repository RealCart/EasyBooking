import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

SaveAddPropertyDetailsParamsEntity _params({
  String title = 'Al-Farabi Residence · 19',
  String address = 'Аль-Фараби, 21',
  int rooms = 2,
}) {
  return SaveAddPropertyDetailsParamsEntity(
    title: title,
    address: address,
    type: PropertyType.room,
    rooms: rooms,
  );
}

Map<String, String> _fieldErrors(Either<Failure, void> result) {
  return result.fold(
    (Failure failure) => (failure as ValidationFailure).fieldErrors,
    (_) => fail('Expected a ValidationFailure'),
  );
}

void main() {
  group('SaveAddPropertyDetailsUsecase', () {
    late FakePropertyManagementRepository repository;
    late SaveAddPropertyDetailsUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = SaveAddPropertyDetailsUsecase(repository);
    });

    test('saves trimmed details with the type and rooms', () async {
      final Either<Failure, void> result = await usecase(
        _params(title: '  Highvill · 5 ', address: ' Кабанбай батыра, 11  '),
      );

      expect(result.isRight, isTrue);
      expect(
        repository.savedDetails.single,
        const SaveAddPropertyDetailsParamsEntity(
          title: 'Highvill · 5',
          address: 'Кабанбай батыра, 11',
          type: PropertyType.room,
          rooms: 2,
        ),
      );
    });

    test('a blank title and address are required, nothing is saved', () async {
      final Either<Failure, void> result = await usecase(
        _params(title: '   ', address: ''),
      );

      expect(_fieldErrors(result), <String, String>{
        AddPropertyFields.title: PropertyErrorCodes.required,
        AddPropertyFields.address: PropertyErrorCodes.required,
      });
      expect(repository.savedDetails, isEmpty);
    });

    for (final int rooms in <int>[0, 21, -1]) {
      test('$rooms rooms are out of range', () async {
        final Either<Failure, void> result = await usecase(
          _params(rooms: rooms),
        );

        expect(_fieldErrors(result), <String, String>{
          AddPropertyFields.rooms: PropertyErrorCodes.outOfRange,
        });
        expect(repository.savedDetails, isEmpty);
      });
    }

    for (final int rooms in <int>[1, 20]) {
      test('$rooms rooms are accepted', () async {
        expect((await usecase(_params(rooms: rooms))).isRight, isTrue);
        expect(repository.savedDetails.single.rooms, rooms);
      });
    }

    test('the reported field errors cannot be changed', () async {
      final Map<String, String> errors = _fieldErrors(
        await usecase(_params(title: '')),
      );

      expect(() => errors['x'] = 'y', throwsUnsupportedError);
    });

    test('passes a repository failure through unchanged', () async {
      repository.saveDetailsResult = const Left<Failure, void>(
        StorageFailure(message: 'disk'),
      );

      expect(
        await usecase(_params()),
        const Left<Failure, void>(StorageFailure(message: 'disk')),
      );
    });
  });
}
