import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';

/// Shared setup of the profile settings screen tests.
abstract final class ProfileDetailHarness {
  /// Text of the page under the pushed screen.
  static const String basePage = 'base page';

  /// The 430 × 932 phone of the design.
  static void usePhoneSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Pumps a base page at `/`, then pushes [screen] (already wrapped in its
  /// own `BlocProvider`) on top of it, so the screen can pop back.
  static Future<GoRouter> pump(
    WidgetTester tester,
    Widget Function() screen, {
    bool settle = true,
  }) async {
    usePhoneSize(tester);
    final GoRouter router = GoRouter(
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text(basePage)),
          routes: <RouteBase>[
            GoRoute(path: 'detail', builder: (_, _) => screen()),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    router.push('/detail');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    return router;
  }

  /// The editable input of the [AppTextField] labelled [label].
  static Finder field(String label) {
    return find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );
  }

  /// The current text of the [AppTextField] labelled [label].
  static String textOf(WidgetTester tester, String label) {
    return tester.widget<TextField>(field(label)).controller!.text;
  }

  /// Scrolls [finder] into view and taps it.
  static Future<void> tapVisible(
    WidgetTester tester,
    Finder finder, {
    bool settle = true,
  }) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// Scrolls the field labelled [label] into view and replaces its text.
  static Future<void> type(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    await tester.ensureVisible(field(label));
    await tester.pump();
    await tester.enterText(field(label), text);
    await tester.pump();
  }

  /// The visible snackbar with [message].
  static Finder snackbar(String message) {
    return find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(message),
    );
  }

  /// The [FilledButton] labelled [label].
  static Finder filledButton(String label) {
    return find.widgetWithText(FilledButton, label);
  }

  static bool isEnabled(WidgetTester tester, Finder button) {
    return tester.widget<FilledButton>(button).onPressed != null;
  }
}
