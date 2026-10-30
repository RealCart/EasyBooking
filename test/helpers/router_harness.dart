import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/widgets/navigation/app_bottom_navigation.dart';

import 'fake_session_storage.dart';

const AuthTokens testTokens = AuthTokens(accessToken: 'access');

/// The real app router over an [AuthSession] backed by a fake storage.
final class RouterHarness {
  RouterHarness._(this.tester, this.session, this.router);

  final WidgetTester tester;
  final AuthSession session;
  final GoRouter router;

  /// Builds the app router and pumps it in a `MaterialApp.router`.
  ///
  /// The router and the session are disposed in tear-down.
  static Future<RouterHarness> pump(
    WidgetTester tester, {
    bool signedIn = true,
    String? initialLocation,
  }) async {
    final AuthSession session = AuthSession(
      sessionStorage: FakeSessionStorage(),
    );
    addTearDown(session.dispose);
    if (signedIn) {
      await session.signIn(testTokens);
    }
    final GoRouter router = AppRouter.create(
      session: session,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return RouterHarness._(tester, session, router);
  }

  /// The location of the top-most route, including the query. Unlike
  /// `currentConfiguration.uri`, it includes routes opened with `push`.
  String get location => router.state.uri.toString();

  Future<void> go(String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  Finder get bottomNavigation => find.byType(AppBottomNavigation);

  /// Taps the bottom navigation item labelled [label].
  Future<void> tapTab(String label) async {
    await tester.tap(
      find.descendant(of: bottomNavigation, matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  int get selectedItemIndex {
    return tester.widget<AppBottomNavigation>(bottomNavigation).selectedIndex;
  }
}
