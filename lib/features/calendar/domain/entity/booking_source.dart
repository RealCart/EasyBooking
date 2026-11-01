/// Where a booking came from.
enum BookingSource {
  airbnb,
  bookingCom,

  /// Entered by the host in EasyBooking («напрямую», «ручная бронь»).
  direct,
}
