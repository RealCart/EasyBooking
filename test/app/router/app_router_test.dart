import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/router/route_not_found_screen.dart';
import 'package:easy_booking/app/router/route_placeholder_screen.dart';

import '../../helpers/router_harness.dart';

String? _redirect(String location, {required bool isAuthenticated}) {
  return AppRouter.redirect(
    isAuthenticated: isAuthenticated,
    uri: Uri.parse(location),
  );
}

/// Every route with the path parameters it needs, its expected location,
/// and whether the bottom navigation stays visible on it.
final class _RouteCase {
  const _RouteCase(
    this.route,
    this.location, {
    this.pathParameters = const <String, String>{},
    this.keepsNavigation = false,
    this.canNavigateSignedIn = true,
  });

  final AppRoute route;
  final String location;
  final Map<String, String> pathParameters;
  final bool keepsNavigation;

  /// Login routes redirect away from a signed-in user.
  final bool canNavigateSignedIn;
}

const Map<String, String> _property = <String, String>{
  AppRoutes.propertyIdParam: 'p1',
};

const List<_RouteCase> _routeCases = <_RouteCase>[
  _RouteCase(AppRoutes.login, '/login', canNavigateSignedIn: false),
  _RouteCase(AppRoutes.verifyCode, '/login/verify'),
  _RouteCase(AppRoutes.accountSetup, '/account-setup'),
  _RouteCase(AppRoutes.today, '/today', keepsNavigation: true),
  _RouteCase(AppRoutes.calendar, '/calendar', keepsNavigation: true),
  _RouteCase(
    AppRoutes.occupancy,
    '/calendar/occupancy',
    keepsNavigation: true,
  ),
  _RouteCase(AppRoutes.channels, '/calendar/channels', keepsNavigation: true),
  _RouteCase(
    AppRoutes.channel,
    '/calendar/channels/c1',
    pathParameters: <String, String>{AppRoutes.channelIdParam: 'c1'},
  ),
  _RouteCase(AppRoutes.properties, '/properties', keepsNavigation: true),
  _RouteCase(
    AppRoutes.favoriteProperties,
    '/properties/favorites',
    keepsNavigation: true,
  ),
  _RouteCase(AppRoutes.property, '/properties/p1', pathParameters: _property),
  _RouteCase(
    AppRoutes.propertyBookings,
    '/properties/p1/bookings',
    pathParameters: _property,
  ),
  _RouteCase(
    AppRoutes.propertySettings,
    '/properties/p1/settings',
    pathParameters: _property,
  ),
  _RouteCase(
    AppRoutes.propertyReady,
    '/properties/p1/ready',
    pathParameters: _property,
  ),
  _RouteCase(AppRoutes.profile, '/profile', keepsNavigation: true),
  _RouteCase(AppRoutes.editProfile, '/profile/edit'),
  _RouteCase(AppRoutes.guests, '/profile/guests', keepsNavigation: true),
  _RouteCase(
    AppRoutes.guest,
    '/profile/guests/g1',
    pathParameters: <String, String>{AppRoutes.guestIdParam: 'g1'},
  ),
  _RouteCase(AppRoutes.team, '/profile/team'),
  _RouteCase(AppRoutes.notificationSettings, '/profile/notifications'),
  _RouteCase(AppRoutes.security, '/profile/security'),
  _RouteCase(AppRoutes.billing, '/profile/billing'),
  _RouteCase(AppRoutes.help, '/profile/help'),
  _RouteCase(AppRoutes.addProperty, '/add-property'),
  _RouteCase(AppRoutes.addPropertyChannels, '/add-property/channels'),
  _RouteCase(AppRoutes.addPropertyTerms, '/add-property/terms'),
  _RouteCase(AppRoutes.newBooking, '/bookings/new'),
  _RouteCase(AppRoutes.newBookingGuest, '/bookings/new/guest'),
  _RouteCase(
    AppRoutes.booking,
    '/bookings/b1',
    pathParameters: <String, String>{AppRoutes.bookingIdParam: 'b1'},
  ),
  _RouteCase(
    AppRoutes.contract,
    '/contracts/k1',
    pathParameters: <String, String>{AppRoutes.contractIdParam: 'k1'},
  ),
  _RouteCase(
    AppRoutes.contractSend,
    '/contracts/k1/send',
    pathParameters: <String, String>{AppRoutes.contractIdParam: 'k1'},
  ),
  _RouteCase(
    AppRoutes.contractStatus,
    '/contracts/k1/status',
    pathParameters: <String, String>{AppRoutes.contractIdParam: 'k1'},
  ),
  _RouteCase(AppRoutes.notifications, '/notifications'),
  _RouteCase(
    AppRoutes.calendarConflict,
    '/calendar-conflicts/x1',
    pathParameters: <String, String>{AppRoutes.conflictIdParam: 'x1'},
  ),
];

void main() {
  group('AppRouter.redirect when signed out', () {
    test('sends the start locations to login without from', () {
      expect(_redirect('/', isAuthenticated: false), '/login');
      expect(_redirect('/today', isAuthenticated: false), '/login');
    });

    test('remembers a deep link in the from query', () {
      expect(
        _redirect('/properties/42', isAuthenticated: false),
        '/login?from=%2Fproperties%2F42',
      );
      expect(
        Uri.parse(
          _redirect('/calendar?month=10', isAuthenticated: false)!,
        ).queryParameters[AppRoutes.fromQuery],
        '/calendar?month=10',
      );
    });

    test('leaves the login flow alone', () {
      expect(_redirect('/login', isAuthenticated: false), isNull);
      expect(_redirect('/login/verify', isAuthenticated: false), isNull);
      expect(
        _redirect('/login?from=%2Fprofile', isAuthenticated: false),
        isNull,
      );
    });

    test('does not treat a path that only starts with login as login', () {
      expect(
        _redirect('/loginx', isAuthenticated: false),
        '/login?from=%2Floginx',
      );
    });
  });

  group('AppRouter.redirect when signed in', () {
    test('sends login to today', () {
      expect(_redirect('/login', isAuthenticated: true), '/today');
    });

    test('sends login to a safe from location', () {
      expect(
        _redirect('/login?from=%2Fproperties%2F42', isAuthenticated: true),
        '/properties/42',
      );
    });

    test('ignores an unsafe from location', () {
      for (final String from in <String>[
        '//evil.example',
        'https://evil.example',
        '/login',
        '/login/verify',
      ]) {
        expect(
          _redirect(
            Uri(
              path: '/login',
              queryParameters: <String, String>{AppRoutes.fromQuery: from},
            ).toString(),
            isAuthenticated: true,
          ),
          '/today',
          reason: from,
        );
      }
    });

    test('leaves verify and other locations alone', () {
      expect(_redirect('/login/verify', isAuthenticated: true), isNull);
      expect(_redirect('/today', isAuthenticated: true), isNull);
      expect(_redirect('/account-setup', isAuthenticated: true), isNull);
      expect(_redirect('/unknown', isAuthenticated: true), isNull);
    });
  });

  group('AppRouter.safeFromLocation', () {
    test('accepts in-app locations with a query', () {
      expect(AppRouter.safeFromLocation('/properties/42'), '/properties/42');
      expect(
        AppRouter.safeFromLocation('/calendar?month=10'),
        '/calendar?month=10',
      );
    });

    test('rejects missing, external, relative and login locations', () {
      for (final String? from in <String?>[
        null,
        '',
        'properties/42',
        'https://evil.example/path',
        '//evil.example/path',
        '/login',
        '/login/verify',
        '/login?from=%2Ftoday',
      ]) {
        expect(AppRouter.safeFromLocation(from), isNull, reason: '$from');
      }
    });
  });

  group('AppRouter navigation', () {
    testWidgets('a signed-out start redirects to login', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
      );

      expect(harness.location, '/login');
      expect(find.text('Вход'), findsOneWidget);
      expect(harness.bottomNavigation, findsNothing);
    });

    testWidgets('a signed-out deep link goes to login with from', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/properties/42',
      );

      expect(harness.location, '/login?from=%2Fproperties%2F42');
    });

    testWidgets('signing in on login opens the from location', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/properties/42',
      );

      await harness.session.signIn(testTokens);
      await tester.pumpAndSettle();

      expect(harness.location, '/properties/42');
      expect(find.text('Ваш объект'), findsOneWidget);
    });

    testWidgets('signing in on plain login opens today', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
      );

      await harness.session.signIn(testTokens);
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      expect(harness.bottomNavigation, findsOneWidget);
    });

    testWidgets('signing out anywhere returns to login', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/profile',
      );

      await harness.session.signOut();
      await tester.pumpAndSettle();

      final Uri uri = Uri.parse(harness.location);
      expect(uri.path, '/login');
      expect(uri.queryParameters[AppRoutes.fromQuery], '/profile');
      expect(harness.bottomNavigation, findsNothing);
    });

    testWidgets('verify code is not redirected when signed in', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/login/verify?phone=%2B77001234567',
      );

      expect(Uri.parse(harness.location).path, '/login/verify');
      expect(find.text('Подтверждение'), findsOneWidget);
    });

    testWidgets('the root path opens today', (WidgetTester tester) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/',
      );

      expect(harness.location, '/today');
      expect(find.text('Сегодня'), findsWidgets);
    });

    testWidgets('an unknown path shows the not-found screen', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/does-not-exist',
      );

      expect(find.byType(RouteNotFoundScreen), findsOneWidget);
      expect(harness.bottomNavigation, findsNothing);
    });

    testWidgets('an unknown nested path shows the not-found screen', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(tester, initialLocation: '/properties/1/nope');

      expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    });
  });

  group('AppRoutes tree', () {
    testWidgets('every route name resolves to its expected location', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      for (final _RouteCase routeCase in _routeCases) {
        expect(
          harness.router.namedLocation(
            routeCase.route.name,
            pathParameters: routeCase.pathParameters,
          ),
          routeCase.location,
          reason: routeCase.route.name,
        );
      }
    });

    testWidgets('every route opens a screen with the expected navigation', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(tester);

      for (final _RouteCase routeCase in _routeCases) {
        if (!routeCase.canNavigateSignedIn) {
          continue;
        }
        await harness.go(routeCase.location);

        expect(
          Uri.parse(harness.location).path,
          routeCase.location,
          reason: routeCase.route.name,
        );
        expect(
          find.byType(RouteNotFoundScreen),
          findsNothing,
          reason: routeCase.route.name,
        );
        expect(
          find.byType(RoutePlaceholderScreen),
          findsOneWidget,
          reason: routeCase.route.name,
        );
        expect(
          harness.bottomNavigation,
          routeCase.keepsNavigation ? findsOneWidget : findsNothing,
          reason: routeCase.route.name,
        );
      }
    });
  });
}
