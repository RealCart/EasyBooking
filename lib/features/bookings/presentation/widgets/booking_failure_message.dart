import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_error_codes.dart';

extension BookingFailureMessage on Failure {
  /// Text for a bookings failure. Known codes get their own message;
  /// anything else falls back to the shared [userMessage].
  String get bookingMessage {
    if (this case ServerFailure(statusCode: 404, code: null)) {
      return 'Бронь не найдена';
    }
    final String? code = switch (this) {
      ValidationFailure(:final String? code) => code,
      ServerFailure(:final String? code) => code,
      _ => null,
    };
    return switch (code) {
      BookingErrorCodes.datesUnavailable => 'Эти даты уже заняты другой бронью',
      BookingErrorCodes.notCancellable => 'Эту бронь уже нельзя отменить',
      BookingErrorCodes.draftNotFound =>
        'Черновик брони устарел. Заполните её заново',
      _ => userMessage,
    };
  }

  /// Whether the step-1 draft is gone, so step 2 has to start over.
  bool get isBookingDraftNotFound {
    return switch (this) {
      ValidationFailure(code: BookingErrorCodes.draftNotFound) => true,
      ServerFailure(code: BookingErrorCodes.draftNotFound) => true,
      _ => false,
    };
  }
}

/// Text for a `fieldErrors` value of the new-booking forms, or `null` when
/// the field has no error.
String? bookingFieldErrorMessage(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  return switch (code) {
    BookingErrorCodes.required => FormValidators.requiredMessage,
    BookingErrorCodes.invalidPhone => FormValidators.invalidPhoneMessage,
    BookingErrorCodes.checkOutBeforeCheckIn =>
      'Выезд должен быть хотя бы на день позже заезда',
    BookingErrorCodes.invalidAmount => FormValidators.invalidAmountMessage,
    BookingErrorCodes.unsupportedSource => 'Выберите другой источник',
    _ => 'Проверьте поле',
  };
}
