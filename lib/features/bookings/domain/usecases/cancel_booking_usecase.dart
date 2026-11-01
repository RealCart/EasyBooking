import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/cancel_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

/// Cancels a booking and returns it updated. A completed or already
/// cancelled booking is a `ValidationFailure` with
/// `BookingErrorCodes.notCancellable`.
final class CancelBookingUsecase
    implements
        Usecase<
          Future<Either<Failure, BookingEntity>>,
          CancelBookingParamsEntity
        > {
  const CancelBookingUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, BookingEntity>> call(
    CancelBookingParamsEntity params,
  ) {
    return _repository.cancelBooking(params.bookingId);
  }
}
