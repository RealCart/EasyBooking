import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

/// The draft of the new booking, if any, with the source's today.
final class GetBookingDraftUsecase
    implements
        Usecase<Future<Either<Failure, CurrentBookingDraftEntity>>, NoParams> {
  const GetBookingDraftUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, CurrentBookingDraftEntity>> call(NoParams params) {
    return _repository.getDraft();
  }
}
