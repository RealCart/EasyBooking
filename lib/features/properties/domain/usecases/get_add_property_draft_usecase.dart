import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';

/// The add-property draft, so every step can prefill what was saved.
final class GetAddPropertyDraftUsecase
    implements
        Usecase<Future<Either<Failure, AddPropertyDraftEntity>>, NoParams> {
  const GetAddPropertyDraftUsecase(this._repository);

  final PropertyManagementRepository _repository;

  @override
  Future<Either<Failure, AddPropertyDraftEntity>> call(NoParams params) {
    return _repository.getAddPropertyDraft();
  }
}
