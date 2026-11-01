import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/route_placeholder_screen.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_detail_header.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_root_header.dart';

/// No app route uses the placeholder while every screen is built, so it is
/// mounted in its own router: `/` as a root route and `/next` pushed on top.
Future<GoRouter> _pumpPlaceholder(WidgetTester tester) async {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Главная'),
      ),
      GoRoute(
        path: '/next',
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Новая бронь'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('RoutePlaceholderScreen', () {
    testWidgets('shows a root header when nothing can be popped', (
      WidgetTester tester,
    ) async {
      await _pumpPlaceholder(tester);

      expect(find.byType(AppRootHeader), findsOneWidget);
      expect(find.byType(AppDetailHeader), findsNothing);
      expect(find.text('Экран в разработке'), findsOneWidget);
    });

    testWidgets('shows a back header on a pushed screen and pops on back', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pumpPlaceholder(tester);

      router.push('/next');
      await tester.pumpAndSettle();

      expect(find.byType(AppDetailHeader), findsOneWidget);
      expect(find.text('Новая бронь'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/');
      expect(find.byType(AppRootHeader), findsOneWidget);
    });
  });
}
