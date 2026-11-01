import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/get_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

final class GetBookingUsecase
    implements
        Usecase<
          Future<Either<Failure, BookingEntity>>,
          GetBookingParamsEntity
        > {
  const GetBookingUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, BookingEntity>> call(GetBookingParamsEntity params) {
    return _repository.getBooking(params.bookingId);
  }
}
