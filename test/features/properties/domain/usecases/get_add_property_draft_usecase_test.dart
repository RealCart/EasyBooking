import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';

import '../../../../helpers/fake_property_management_repository.dart';

void main() {
  group('GetAddPropertyDraftUsecase', () {
    late FakePropertyManagementRepository repository;
    late GetAddPropertyDraftUsecase usecase;

    setUp(() {
      repository = FakePropertyManagementRepository();
      usecase = GetAddPropertyDraftUsecase(repository);
    });

    test('returns the stored draft', () async {
      repository.draftResult = const Right<Failure, AddPropertyDraftEntity>(
        testFilledDraft,
      );

      expect(
        await usecase(const NoParams()),
        const Right<Failure, AddPropertyDraftEntity>(testFilledDraft),
      );
      expect(repository.draftCount, 1);
    });

    test('passes a failure through unchanged', () async {
      repository.draftResult = const Left<Failure, AddPropertyDraftEntity>(
        StorageFailure(),
      );

      expect(
        await usecase(const NoParams()),
        const Left<Failure, AddPropertyDraftEntity>(StorageFailure()),
      );
    });
  });
}
