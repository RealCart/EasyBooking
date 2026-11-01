import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/extensions/date_time_extensions.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/core/utils/validators.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_fields.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';

/// Validates step 1 of a new booking and saves it as the draft.
///
/// Rules: a property is chosen, check-out is at least one night after
/// check-in, the first name is filled, and the phone is a complete
/// Kazakhstan number. A broken rule is a `ValidationFailure` whose
/// `fieldErrors` map `BookingFields` keys to `BookingErrorCodes`. The names
/// are trimmed and the phone is sent in E.164.
final class SaveBookingDraftUsecase
    implements
        Usecase<
          Future<Either<Failure, BookingDraftEntity>>,
          SaveBookingDraftParamsEntity
        > {
  const SaveBookingDraftUsecase(this._repository);

  final BookingsRepository _repository;

  @override
  Future<Either<Failure, BookingDraftEntity>> call(
    SaveBookingDraftParamsEntity params,
  ) async {
    final String propertyId = params.propertyId.trim();
    final String firstName = params.firstName.trim();
    final String lastName = params.lastName.trim();
    final String? phone = PhoneNumber.toE164(params.phone);

    final Map<String, String> fieldErrors = <String, String>{
      if (propertyId.isEmpty)
        BookingFields.property: BookingErrorCodes.required,
      if (params.checkIn.nightsUntil(params.checkOut) < 1)
        BookingFields.checkOut: BookingErrorCodes.checkOutBeforeCheckIn,
      if (!Validators.isNotBlank(firstName))
        BookingFields.firstName: BookingErrorCodes.required,
      if (!Validators.isNotBlank(params.phone))
        BookingFields.phone: BookingErrorCodes.required
      else if (phone == null)
        BookingFields.phone: BookingErrorCodes.invalidPhone,
    };
    // `phone == null` is already a field error; checking it promotes `phone`.
    if (fieldErrors.isNotEmpty || phone == null) {
      return Left<Failure, BookingDraftEntity>(
        ValidationFailure(
          fieldErrors: Map<String, String>.unmodifiable(fieldErrors),
        ),
      );
    }

    return _repository.saveDraft(
      SaveBookingDraftParamsEntity(
        propertyId: propertyId,
        checkIn: params.checkIn,
        checkOut: params.checkOut,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      ),
    );
  }
}
