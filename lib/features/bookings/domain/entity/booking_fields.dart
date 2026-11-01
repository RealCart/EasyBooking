/// Field keys of the new-booking forms, used in
/// `ValidationFailure.fieldErrors`.
///
/// There is no bookings API yet; when it exists, alias the `AppApi` request
/// keys here, as `AccountFields` does.
abstract final class BookingFields {
  // «Когда и где».
  static const String property = 'property';
  static const String checkIn = 'check_in';
  static const String checkOut = 'check_out';
  static const String firstName = 'first_name';
  static const String lastName = 'last_name';
  static const String phone = 'phone';

  // «Цена и источник».
  static const String totalPrice = 'total_price';
  static const String deposit = 'deposit';
  static const String source = 'source';
}
