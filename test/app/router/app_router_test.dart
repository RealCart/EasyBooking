import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/router/route_not_found_screen.dart';
import 'package:easy_booking/app/router/route_placeholder_screen.dart';
import 'package:easy_booking/features/auth/data/models/verify_code_response_model.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/presentation/screens/account_setup_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/login_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:easy_booking/features/home/presentation/screens/home_screen.dart';

import '../../helpers/router_harness.dart';

String? _redirect(
  String location, {
  required bool isAuthenticated,
  bool isAccountSetupPending = false,
}) {
  return AppRouter.redirect(
    isAuthenticated: isAuthenticated,
    isAccountSetupPending: isAccountSetupPending,
    uri: Uri.parse(location),
  );
}

String? _pending(String location) {
  return _redirect(
    location,
    isAuthenticated: true,
    isAccountSetupPending: true,
  );
}

String _withFrom(String path, String from) {
  return Uri(
    path: path,
    queryParameters: <String, String>{AppRoutes.fromQuery: from},
  ).toString();
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
    this.screen = RoutePlaceholderScreen,
  });

  final AppRoutes route;
  final String location;
  final Map<String, String> pathParameters;
  final bool keepsNavigation;

  /// The screen type the route opens.
  final Type screen;

  /// Auth routes redirect away from a signed-in user who finished setup.
  final bool canNavigateSignedIn;
}

const Map<String, String> _property = <String, String>{
  AppRoutes.propertyIdParam: 'p1',
};

const List<_RouteCase> _routeCases = <_RouteCase>[
  _RouteCase(AppRoutes.login, '/login', canNavigateSignedIn: false),
  _RouteCase(AppRoutes.verifyCode, '/login/verify', canNavigateSignedIn: false),
  _RouteCase(
    AppRoutes.accountSetup,
    '/account-setup',
    canNavigateSignedIn: false,
  ),
  _RouteCase(
    AppRoutes.today,
    '/today',
    keepsNavigation: true,
    screen: HomeScreen,
  ),
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

    test('sends account setup to login without from', () {
      expect(_redirect('/account-setup', isAuthenticated: false), '/login');
      expect(
        _redirect('/account-setup?from=%2Fprofile', isAuthenticated: false),
        '/login',
      );
    });

    test('ignores a pending flag without a session', () {
      expect(
        _redirect(
          '/account-setup',
          isAuthenticated: false,
          isAccountSetupPending: true,
        ),
        '/login',
      );
      expect(
        _redirect(
          '/login',
          isAuthenticated: false,
          isAccountSetupPending: true,
        ),
        isNull,
      );
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

  group('AppRouter.redirect when account setup is pending', () {
    test('leaves account setup alone', () {
      expect(_pending('/account-setup'), isNull);
      expect(_pending('/account-setup?from=%2Fproperties%2F42'), isNull);
    });

    test('sends the login flow to account setup with its safe from', () {
      expect(
        _pending('/login?from=%2Fproperties%2F42'),
        '/account-setup?from=%2Fproperties%2F42',
      );
      expect(
        _pending(
          '/login/verify?phone=%2B77001234567&resendAfter=30'
          '&from=%2Fcalendar%3Fmonth%3D10',
        ),
        _withFrom('/account-setup', '/calendar?month=10'),
      );
    });

    test('sends the login flow without a safe from to plain setup', () {
      for (final String location in <String>[
        '/login',
        '/login/verify?phone=%2B77001234567',
        _withFrom('/login', '//evil.example'),
        _withFrom('/login', 'https://evil.example'),
        _withFrom('/login', '/today'),
        _withFrom('/login', '/'),
        _withFrom('/login', '/account-setup'),
        _withFrom('/login/verify', '/login'),
      ]) {
        expect(_pending(location), '/account-setup', reason: location);
      }
    });

    test('uses any other location as from', () {
      expect(
        _pending('/properties/42'),
        '/account-setup?from=%2Fproperties%2F42',
      );
      expect(
        _pending('/calendar?month=10'),
        _withFrom('/account-setup', '/calendar?month=10'),
      );
      expect(_pending('/unknown'), '/account-setup?from=%2Funknown');
    });

    test('does not use the start locations as from', () {
      expect(_pending('/'), '/account-setup');
      expect(_pending('/today'), '/account-setup');
    });
  });

  group('AppRouter.redirect when signed in', () {
    test('sends login to today', () {
      expect(_redirect('/login', isAuthenticated: true), '/today');
    });

    test('sends verify to today', () {
      expect(
        _redirect('/login/verify?phone=%2B77001234567', isAuthenticated: true),
        '/today',
      );
    });

    test('sends account setup to a safe from location or today', () {
      expect(_redirect('/account-setup', isAuthenticated: true), '/today');
      expect(
        _redirect(
          '/account-setup?from=%2Fproperties%2F42',
          isAuthenticated: true,
        ),
        '/properties/42',
      );
      expect(
        _redirect(
          _withFrom('/account-setup', '//evil.example'),
          isAuthenticated: true,
        ),
        '/today',
      );
    });

    test('sends verify with from to that location', () {
      expect(
        _redirect(
          '/login/verify?phone=%2B77001234567&from=%2Fprofile',
          isAuthenticated: true,
        ),
        '/profile',
      );
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
        '/',
        '/today',
        '/account-setup',
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

    test('leaves other locations alone', () {
      expect(_redirect('/today', isAuthenticated: true), isNull);
      expect(_redirect('/properties/42', isAuthenticated: true), isNull);
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

    test('rejects the root, today and account setup', () {
      for (final String from in <String>[
        '/',
        '/today',
        '/today?tab=1',
        '/account-setup',
        '/account-setup?from=%2Fprofile',
      ]) {
        expect(AppRouter.safeFromLocation(from), isNull, reason: from);
      }
    });

    test('accepts paths that only start like a rejected one', () {
      expect(AppRouter.safeFromLocation('/todayx'), '/todayx');
      expect(AppRouter.safeFromLocation('/loginx'), '/loginx');
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

    testWidgets('verify code redirects a signed-in user to today', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/login/verify?phone=%2B77001234567',
      );

      expect(harness.location, '/today');
      expect(find.byType(VerifyCodeScreen), findsNothing);
    });

    testWidgets('signing in with pending setup opens setup and keeps from', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/properties/42',
      );
      expect(harness.location, '/login?from=%2Fproperties%2F42');

      await harness.session.signIn(testTokens, isAccountSetupPending: true);
      await tester.pumpAndSettle();

      expect(harness.location, '/account-setup?from=%2Fproperties%2F42');
      expect(find.byType(AccountSetupScreen), findsOneWidget);
      expect(harness.bottomNavigation, findsNothing);

      await harness.session.completeAccountSetup();
      await tester.pumpAndSettle();

      expect(harness.location, '/properties/42');
      expect(find.text('Ваш объект'), findsOneWidget);
    });

    testWidgets('completing setup without from opens today', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
      );

      await harness.session.signIn(testTokens, isAccountSetupPending: true);
      await tester.pumpAndSettle();
      expect(harness.location, '/account-setup');

      await harness.session.completeAccountSetup();
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      expect(harness.bottomNavigation, findsOneWidget);
    });

    testWidgets('a pending session keeps the user on account setup', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        accountSetupPending: true,
      );
      expect(harness.location, '/account-setup');

      await harness.go('/profile');

      expect(harness.location, '/account-setup?from=%2Fprofile');
      expect(find.byType(AccountSetupScreen), findsOneWidget);
    });

    testWidgets('a pending deep link opens setup with that location as from', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        accountSetupPending: true,
        initialLocation: '/properties/42',
      );

      expect(harness.location, '/account-setup?from=%2Fproperties%2F42');
    });

    testWidgets('leaving account setup signs out and returns to login', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        accountSetupPending: true,
      );

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.session.isAuthenticated, isFalse);
      expect(harness.storage.storedTokens, isNull);
      expect(harness.location, '/login');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a new user goes from login through setup to from', (
      WidgetTester tester,
    ) async {
      tester.view
        ..physicalSize = const Size(430, 932)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/properties/42',
      );
      harness.remote.verifyResponse = const VerifyCodeResponseModel(
        accessToken: 'new-access',
        isNewUser: true,
      );

      await tester.enterText(find.byType(TextField), '7001234567');
      await tester.pump();
      await tester.tap(find.text('Получить код'));
      await tester.pumpAndSettle();

      expect(harness.remote.sentPhones, <String>['+77001234567']);
      final Uri verify = Uri.parse(harness.location);
      expect(verify.path, '/login/verify');
      expect(verify.queryParameters, <String, String>{
        AppRoutes.phoneQuery: '+77001234567',
        AppRoutes.resendAfterQuery: '30',
        AppRoutes.fromQuery: '/properties/42',
      });
      expect(find.byType(VerifyCodeScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), '482913');
      await tester.pumpAndSettle();

      expect(harness.remote.verifyCalls.single, (
        phone: '+77001234567',
        code: '482913',
      ));
      expect(harness.session.isAccountSetupPending, isTrue);
      expect(harness.location, '/account-setup?from=%2Fproperties%2F42');
      expect(find.byType(AccountSetupScreen), findsOneWidget);
      expect(find.byType(VerifyCodeScreen), findsNothing);

      final Finder fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Айгерим');
      await tester.enterText(fields.at(1), 'Садыкова');
      await tester.enterText(fields.at(2), 'aigerim@example.kz');
      await tester.enterText(fields.at(3), 'Esentai Stay');
      await tester.tap(find.text('Город и часовой пояс'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Астана'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();

      final Map<String, Object?> body = harness
          .remote
          .createAccountRequests
          .single
          .toJson();
      expect(body['city'], KazakhstanCities.astana.id);
      expect(harness.session.isAccountSetupPending, isFalse);
      expect(harness.storage.storedAccountSetupPending, isFalse);
      expect(harness.location, '/properties/42');
      expect(find.text('Ваш объект'), findsOneWidget);
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

  group('verifyCode route', () {
    testWidgets('without a phone redirects to login', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/login/verify',
      );

      expect(harness.location, '/login');
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('with an invalid phone redirects to login keeping from', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/login/verify?phone=123&from=%2Fprofile',
      );

      expect(harness.location, '/login?from=%2Fprofile');
    });

    testWidgets('normalizes a national phone for the screen', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/login/verify?phone=7001234567&resendAfter=30',
      );

      expect(find.byType(VerifyCodeScreen), findsOneWidget);
      expect(find.text('Отправили на +7 700 123 45 67'), findsOneWidget);
      expect(find.text('Можно через 00:30'), findsOneWidget);
    });

    for (final String resendAfter in <String>['', 'abc', '-5', '1.5']) {
      testWidgets('resendAfter "$resendAfter" defaults to zero', (
        WidgetTester tester,
      ) async {
        await RouterHarness.pump(
          tester,
          signedIn: false,
          initialLocation:
              '/login/verify?phone=%2B77001234567&resendAfter=$resendAfter',
        );

        expect(find.byType(VerifyCodeScreen), findsOneWidget);
        expect(find.textContaining('Можно через'), findsNothing);
      });
    }

    testWidgets('a missing resendAfter defaults to zero', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(
        tester,
        signedIn: false,
        initialLocation: '/login/verify?phone=%2B77001234567',
      );

      expect(find.textContaining('Можно через'), findsNothing);
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
          find.byType(routeCase.screen),
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
