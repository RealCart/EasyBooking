import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/current_booking_draft_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_guest_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/create_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/save_booking_draft_params_entity.dart';

/// Served by a mock source until the bookings API exists.
///
/// A new booking is made in two steps on separate screens, so step 1 is
/// saved as a server-side draft ([saveDraft]) that step 2 reads ([getDraft])
/// and turns into a booking ([createBooking]).
abstract interface class BookingsRepository {
  /// The booking [id]; an unknown id is a failure.
  Future<Either<Failure, BookingEntity>> getBooking(String id);

  /// Cancels the booking [id] and returns it updated.
  Future<Either<Failure, BookingEntity>> cancelBooking(String id);

  /// Guests of earlier bookings whose name or phone contains [query].
  Future<Either<Failure, List<BookingGuestEntity>>> searchGuests(String query);

  /// The current draft, `null` when there is none, with the source's today.
  Future<Either<Failure, CurrentBookingDraftEntity>> getDraft();

  /// Replaces the current draft with [params], already validated, and
  /// returns it with its quote and availability.
  Future<Either<Failure, BookingDraftEntity>> saveDraft(
    SaveBookingDraftParamsEntity params,
  );

  /// Creates a booking from the draft and returns its id; the draft is
  /// removed.
  Future<Either<Failure, String>> createBooking(
    CreateBookingParamsEntity params,
  );
}
