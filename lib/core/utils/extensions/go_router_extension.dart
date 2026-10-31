import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract interface class GoRouterWrapper {
  Widget wrappedRoute(BuildContext context);
}

extension GoRouteExtension on GoRoute {
  static Widget _buildChild(BuildContext context, Widget child) {
    if (child is GoRouterWrapper) {
      return (child as GoRouterWrapper).wrappedRoute(context);
    }

    return child;
  }

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
      builder: pageBuilder == null
          ? (context, state) {
              final Widget child = wrappedBuilder.call(context, state);

              return _buildChild(context, child);
            }
          : null,
      pageBuilder: pageBuilder == null
          ? null
          : (context, state) {
              final Widget child = wrappedBuilder.call(context, state);

              return pageBuilder.call(
                context,
                state,
                _buildChild(context, child),
              );
            },
    );
  }
}
