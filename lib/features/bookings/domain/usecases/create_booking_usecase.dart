import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

/// Validates step 2 of a new booking and creates the booking from the
/// draft; returns the id of the new booking.
///
/// Rules: the total is more than zero, the deposit is not negative, and the
/// source is one of `BookingSource.manual`. A broken rule is a
/// `ValidationFailure` whose `fieldErrors` map `BookingFields` keys to
/// `BookingErrorCodes`. The source answers dates taken in the meantime with
/// a `ValidationFailure` coded `BookingErrorCodes.datesUnavailable`, and a
/// stale draft with a `ServerFailure` coded `BookingErrorCodes.draftNotFound`.
final class CreateBookingUsecase
    implements
        Usecase<Future<Either<Failure, String>>, CreateBookingParamsEntity> {
  const CreateBookingUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, String>> call(CreateBookingParamsEntity params) async {
    final Map<String, String> fieldErrors = <String, String>{
      if (params.totalPrice <= 0)
        BookingFields.totalPrice: BookingErrorCodes.invalidAmount,
      if (params.deposit < 0)
        BookingFields.deposit: BookingErrorCodes.invalidAmount,
      if (!params.source.isManual)
        BookingFields.source: BookingErrorCodes.unsupportedSource,
    };
    if (fieldErrors.isNotEmpty) {
      return Left<Failure, String>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    final String comment = params.comment?.trim() ?? '';
    return _repository.createBooking(
      CreateBookingParamsEntity(
        draftId: params.draftId,
        totalPrice: params.totalPrice,
        deposit: params.deposit,
        source: params.source,
        comment: comment.isEmpty ? null : comment,
        createContract: params.createContract,
      ),
    );
  }
}
