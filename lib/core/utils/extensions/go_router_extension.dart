import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract interface class GoRouterWrapper {
  Widget wrappedRoute(BuildContext context);
}

extension GoRouteExtension on GoRoute {
  static GoRoute wrappedRoute({
    required String path,
    required Widget Function(BuildContext context, GoRouterState state)
    wrappedBuilder,
    String? name,
    Page<dynamic> Function(
      BuildContext context,
      GoRouterState state,
      Widget child,
    )?
    pageBuilder,
    GlobalKey<NavigatorState>? parentNavigatorKey,
    FutureOr<String?> Function(BuildContext context, GoRouterState state)?
    redirect,
    FutureOr<bool> Function(BuildContext context, GoRouterState state)? onExit,
    bool caseSensitive = true,
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return GoRoute(
      path: path,
      name: name,
      parentNavigatorKey: parentNavigatorKey,
      redirect: redirect,
      onExit: onExit,
      caseSensitive: caseSensitive,
      routes: routes,
      pageBuilder: (context, state) {
        final Widget screen = wrappedBuilder.call(context, state);
        final Widget child = screen is GoRouterWrapper
            ? (screen as GoRouterWrapper).wrappedRoute(context)
            : screen;

        return pageBuilder?.call(context, state, child) ??
            _materialPage(state, child);
      },
    );
  }

  // go_router 18 detects the app type through `package:material_ui`, so it
  // does not recognise the framework's `MaterialApp` and falls back to
  // `NoTransitionPage` for `builder:` routes. Building the `MaterialPage`
  // here keeps the platform transitions and the iOS back swipe.
  static Page<void> _materialPage(GoRouterState state, Widget child) {
    return MaterialPage<void>(
      key: state.pageKey,
      name: state.name,
      arguments: state.extra,
      restorationId: state.pageKey.value,
      child: child,
    );
  }
}
