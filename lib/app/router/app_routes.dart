/// Every screen of the app: the value's [name] is the route name and
/// [path] its path pattern, relative to the parent route. Top-level paths
/// start with `/`. Navigate by name so paths can change freely:
///
/// ```dart
/// context.pushNamed(
///   AppRoutes.property.name,
///   pathParameters: {AppRoutes.propertyIdParam: propertyId},
/// );
/// ```
enum AppRoutes {
  /// Not a screen: redirects to [today].
  root('/'),

  // Authentication, shown without the bottom navigation.
  login('/login'),
  verifyCode('verify'),
  accountSetup('/account-setup'),

  // Today tab.
  today('/today'),

  // Calendar tab.
  calendar('/calendar'),
  occupancy('occupancy'),
  channels('channels'),
  channel(':$channelIdParam'),

  // Properties tab.
  properties('/properties'),
  favoriteProperties('favorites'),
  property('/properties/:$propertyIdParam'),
  propertyBookings('bookings'),
  propertySettings('settings'),

  /// Confirmation after the add-property flow. Open it with `goNamed` so the
  /// flow is removed from the stack.
  propertyReady('ready'),

  // Profile tab.
  profile('/profile'),
  editProfile('edit'),
  guests('guests'),
  guest(':$guestIdParam'),
  team('team'),
  notificationSettings('notifications'),
  security('security'),
  billing('billing'),
  help('help'),

  // Flows and details shown over the bottom navigation.
  addProperty('/add-property'),
  addPropertyChannels('channels'),
  addPropertyTerms('terms'),
  newBooking('/bookings/new'),
  newBookingGuest('guest'),
  booking('/bookings/:$bookingIdParam'),
  contract('/contracts/:$contractIdParam'),
  contractSend('send'),
  contractStatus('status'),
  notifications('/notifications'),
  calendarConflict('/calendar-conflicts/:$conflictIdParam');

  const AppRoutes(this.path);

  final String path;

  // Path parameters.
  static const String propertyIdParam = 'propertyId';
  static const String bookingIdParam = 'bookingId';
  static const String contractIdParam = 'contractId';
  static const String guestIdParam = 'guestId';
  static const String channelIdParam = 'channelId';
  static const String conflictIdParam = 'conflictId';

  // Query parameters.
  /// Phone number the SMS code was sent to, on [verifyCode].
  static const String phoneQuery = 'phone';

  /// Seconds before another SMS code may be requested, on [verifyCode].
  static const String resendAfterQuery = 'resendAfter';

  /// Location to open after sign-in, on [login], [verifyCode], and
  /// [accountSetup]. Forward it when moving between those screens.
  static const String fromQuery = 'from';
}
