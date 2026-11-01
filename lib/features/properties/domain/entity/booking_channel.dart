/// A booking platform whose calendar a property can be connected to.
///
/// [title] is the platform's brand name, as it appears in
/// `PropertyEntity.channelNames`; it is not translated.
enum BookingChannel {
  bookingCom('Booking.com'),
  airbnb('Airbnb'),
  krisha('Krisha');

  const BookingChannel(this.title);

  final String title;
}
