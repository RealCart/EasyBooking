import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';

final class _WrappedScreen extends StatelessWidget implements GoRouterWrapper {
  const _WrappedScreen();

  @override
  Widget wrappedRoute(BuildContext context) {
    return ColoredBox(color: Colors.white, child: this);
  }

  @override
  Widget build(BuildContext context) => const Text('wrapped');
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  Page<dynamic> Function(BuildContext, GoRouterState, Widget)? pageBuilder,
}) async {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRouteExtension.wrappedRoute(
        path: '/',
        wrappedBuilder: (_, _) => const Text('home'),
      ),
      GoRouteExtension.wrappedRoute(
        path: '/next',
        pageBuilder: pageBuilder,
        wrappedBuilder: (_, _) => const _WrappedScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return router;
}

void main() {
  group('GoRouteExtension.wrappedRoute', () {
    testWidgets('pushes a material page that animates in', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pumpRouter(tester);

      router.push('/next');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final ModalRoute<dynamic> route = ModalRoute.of(
        tester.element(find.text('wrapped')),
      )!;
      expect(route, isA<PageRoute<dynamic>>());
      expect(route.settings, isA<MaterialPage<void>>());
      expect(route.transitionDuration, greaterThan(Duration.zero));
      expect(route.animation!.value, inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(route.animation!.value, 1);
    });

    testWidgets('builds the GoRouterWrapper of the screen', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pumpRouter(tester);

      router.push('/next');
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(_WrappedScreen),
          matching: find.byType(ColoredBox),
        ),
        findsWidgets,
      );
    });

    testWidgets('uses a supplied page builder instead', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pumpRouter(
        tester,
        pageBuilder: (_, GoRouterState state, Widget child) =>
            NoTransitionPage<void>(key: state.pageKey, child: child),
      );

      router.push('/next');
      await tester.pump();

      final ModalRoute<dynamic> route = ModalRoute.of(
        tester.element(find.text('wrapped')),
      )!;
      expect(route.settings, isA<NoTransitionPage<void>>());
      expect(find.byType(ColoredBox), findsWidgets);
    });
  });
}
