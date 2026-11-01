import 'package:easy_booking/core/utils/error/field_error_codes.dart';

/// Error codes of the bookings feature, used in `ValidationFailure.code`,
/// `ServerFailure.code`, and as `ValidationFailure.fieldErrors` values.
///
/// Codes shared with other features alias [FieldErrorCodes].
abstract final class BookingErrorCodes {
  // Request codes.

  /// The dates overlap another booking of the property.
  static const String datesUnavailable = 'dates_unavailable';

  /// The booking is completed or already cancelled.
  static const String notCancellable = 'not_cancellable';

  /// The draft was replaced or already turned into a booking (HTTP 404).
  static const String draftNotFound = 'draft_not_found';

  // Field codes.
  static const String required = FieldErrorCodes.required;
  static const String invalidPhone = FieldErrorCodes.invalidPhone;

  /// Check-out is not at least one night after check-in.
  static const String checkOutBeforeCheckIn = 'check_out_before_check_in';

  /// A price below its minimum (total: more than 0, deposit: 0 or more).
  static const String invalidAmount = 'invalid_amount';

  /// A channel source (Airbnb, Booking.com) on a booking added by hand.
  static const String unsupportedSource = 'unsupported_source';
}
