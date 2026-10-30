/// A route's unique [name] and its [path] pattern relative to the parent
/// route. Top-level paths start with `/`.
final class AppRoute {
  const AppRoute(this.name, this.path);

  final String name;
  final String path;
}

/// Every route of the app. Navigate by name so paths can change freely:
///
/// ```dart
/// context.pushNamed(
///   AppRoutes.property.name,
///   pathParameters: {AppRoutes.propertyIdParam: propertyId},
/// );
/// ```
abstract final class AppRoutes {
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

  /// Location to open after sign-in, on [login] and [verifyCode].
  static const String fromQuery = 'from';

  // Authentication, shown without the bottom navigation.
  static const AppRoute login = AppRoute('login', '/login');
  static const AppRoute verifyCode = AppRoute('verifyCode', 'verify');
  static const AppRoute accountSetup = AppRoute(
    'accountSetup',
    '/account-setup',
  );

  // Today tab.
  static const AppRoute today = AppRoute('today', '/today');

  // Calendar tab.
  static const AppRoute calendar = AppRoute('calendar', '/calendar');
  static const AppRoute occupancy = AppRoute('occupancy', 'occupancy');
  static const AppRoute channels = AppRoute('channels', 'channels');
  static const AppRoute channel = AppRoute('channel', ':$channelIdParam');

  // Properties tab.
  static const AppRoute properties = AppRoute('properties', '/properties');
  static const AppRoute favoriteProperties = AppRoute(
    'favoriteProperties',
    'favorites',
  );
  static const AppRoute property = AppRoute(
    'property',
    '/properties/:$propertyIdParam',
  );
  static const AppRoute propertyBookings = AppRoute(
    'propertyBookings',
    'bookings',
  );
  static const AppRoute propertySettings = AppRoute(
    'propertySettings',
    'settings',
  );

  /// Confirmation after the add-property flow. Open it with `goNamed` so the
  /// flow is removed from the stack.
  static const AppRoute propertyReady = AppRoute('propertyReady', 'ready');

  // Profile tab.
  static const AppRoute profile = AppRoute('profile', '/profile');
  static const AppRoute editProfile = AppRoute('editProfile', 'edit');
  static const AppRoute guests = AppRoute('guests', 'guests');
  static const AppRoute guest = AppRoute('guest', ':$guestIdParam');
  static const AppRoute team = AppRoute('team', 'team');
  static const AppRoute notificationSettings = AppRoute(
    'notificationSettings',
    'notifications',
  );
  static const AppRoute security = AppRoute('security', 'security');
  static const AppRoute billing = AppRoute('billing', 'billing');
  static const AppRoute help = AppRoute('help', 'help');

  // Flows and details shown over the bottom navigation.
  static const AppRoute addProperty = AppRoute('addProperty', '/add-property');
  static const AppRoute addPropertyChannels = AppRoute(
    'addPropertyChannels',
    'channels',
  );
  static const AppRoute addPropertyTerms = AppRoute(
    'addPropertyTerms',
    'terms',
  );
  static const AppRoute newBooking = AppRoute('newBooking', '/bookings/new');
  static const AppRoute newBookingGuest = AppRoute('newBookingGuest', 'guest');
  static const AppRoute booking = AppRoute(
    'booking',
    '/bookings/:$bookingIdParam',
  );
  static const AppRoute contract = AppRoute(
    'contract',
    '/contracts/:$contractIdParam',
  );
  static const AppRoute contractSend = AppRoute('contractSend', 'send');
  static const AppRoute contractStatus = AppRoute('contractStatus', 'status');
  static const AppRoute notifications = AppRoute(
    'notifications',
    '/notifications',
  );
  static const AppRoute calendarConflict = AppRoute(
    'calendarConflict',
    '/calendar-conflicts/:$conflictIdParam',
  );
}
