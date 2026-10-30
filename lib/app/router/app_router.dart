import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/router/app_shell_screen.dart';
import 'package:easy_booking/app/router/route_not_found_screen.dart';
import 'package:easy_booking/app/router/route_placeholder_screen.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';

abstract final class AppRouter {
  /// Builds the app router. It re-evaluates redirects whenever [session]
  /// signs in or out.
  ///
  /// Routes inside a tab keep the bottom navigation. Top-level routes and
  /// tab routes with `parentNavigatorKey: rootNavigatorKey` cover it, as the
  /// detail screens do in the design.
  static GoRouter create({
    required AuthSession session,
    String? initialLocation,
  }) {
    final GlobalKey<NavigatorState> rootNavigatorKey =
        GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation ?? AppRoutes.today.path,
      refreshListenable: session,
      redirect: (BuildContext context, GoRouterState state) {
        return redirect(
          isAuthenticated: session.isAuthenticated,
          uri: state.uri,
        );
      },
      errorBuilder: (_, GoRouterState state) {
        AppLogger.warning(
          'Navigation failed for ${state.uri.path}',
          error: state.error,
        );
        return const RouteNotFoundScreen();
      },
      routes: <RouteBase>[
        GoRoute(path: '/', redirect: (_, _) => AppRoutes.today.path),
        ..._authRoutes(),
        _tabs(rootNavigatorKey),
        ..._flowRoutes(),
      ],
    );
  }

  /// Sends signed-out users to login, remembering where they were going in
  /// [AppRoutes.fromQuery], and sends signed-in users away from login.
  ///
  /// [AppRoutes.verifyCode] is left alone for signed-in users: after the code
  /// is accepted, that screen decides between account setup and `from`.
  static String? redirect({required bool isAuthenticated, required Uri uri}) {
    final String path = uri.path;
    final bool isLoginFlow =
        path == AppRoutes.login.path ||
        path.startsWith('${AppRoutes.login.path}/');

    if (!isAuthenticated) {
      if (isLoginFlow) {
        return null;
      }
      final String from = uri.toString();
      return Uri(
        path: AppRoutes.login.path,
        queryParameters: path == '/' || path == AppRoutes.today.path
            ? null
            : <String, String>{AppRoutes.fromQuery: from},
      ).toString();
    }

    if (path == AppRoutes.login.path) {
      return safeFromLocation(uri.queryParameters[AppRoutes.fromQuery]) ??
          AppRoutes.today.path;
    }
    return null;
  }

  /// Returns [from] when it is an in-app location outside the login flow.
  static String? safeFromLocation(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return null;
    }
    final String path = Uri.tryParse(from)?.path ?? '';
    if (path.isEmpty ||
        path == AppRoutes.login.path ||
        path.startsWith('${AppRoutes.login.path}/')) {
      return null;
    }
    return from;
  }

  static List<RouteBase> _authRoutes() {
    return <RouteBase>[
      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Вход'),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.verifyCode.name,
            path: AppRoutes.verifyCode.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Подтверждение'),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.accountSetup.name,
        path: AppRoutes.accountSetup.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Ваш аккаунт'),
      ),
    ];
  }

  static StatefulShellRoute _tabs(GlobalKey<NavigatorState> rootNavigatorKey) {
    return StatefulShellRoute.indexedStack(
      builder: (_, _, StatefulNavigationShell navigationShell) {
        return AppShellScreen(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.today.name,
              path: AppRoutes.today.path,
              builder: (_, _) => const RoutePlaceholderScreen(title: 'Сегодня'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.calendar.name,
              path: AppRoutes.calendar.path,
              builder: (_, _) =>
                  const RoutePlaceholderScreen(title: 'Календарь'),
              routes: <RouteBase>[
                GoRoute(
                  name: AppRoutes.occupancy.name,
                  path: AppRoutes.occupancy.path,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Занятость'),
                ),
                GoRoute(
                  name: AppRoutes.channels.name,
                  path: AppRoutes.channels.path,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Каналы'),
                  routes: <RouteBase>[
                    GoRoute(
                      name: AppRoutes.channel.name,
                      path: AppRoutes.channel.path,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (_, _) =>
                          const RoutePlaceholderScreen(title: 'Канал'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.properties.name,
              path: AppRoutes.properties.path,
              builder: (_, _) => const RoutePlaceholderScreen(title: 'Объекты'),
              routes: <RouteBase>[
                GoRoute(
                  name: AppRoutes.favoriteProperties.name,
                  path: AppRoutes.favoriteProperties.path,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Избранные'),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.profile.name,
              path: AppRoutes.profile.path,
              builder: (_, _) => const RoutePlaceholderScreen(title: 'Профиль'),
              routes: <RouteBase>[
                GoRoute(
                  name: AppRoutes.editProfile.name,
                  path: AppRoutes.editProfile.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) => const RoutePlaceholderScreen(
                    title: 'Редактировать профиль',
                  ),
                ),
                GoRoute(
                  name: AppRoutes.guests.name,
                  path: AppRoutes.guests.path,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Гости и договоры'),
                  routes: <RouteBase>[
                    GoRoute(
                      name: AppRoutes.guest.name,
                      path: AppRoutes.guest.path,
                      parentNavigatorKey: rootNavigatorKey,
                      builder: (_, _) =>
                          const RoutePlaceholderScreen(title: 'Гость'),
                    ),
                  ],
                ),
                GoRoute(
                  name: AppRoutes.team.name,
                  path: AppRoutes.team.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Команда и доступ'),
                ),
                GoRoute(
                  name: AppRoutes.notificationSettings.name,
                  path: AppRoutes.notificationSettings.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Уведомления'),
                ),
                GoRoute(
                  name: AppRoutes.security.name,
                  path: AppRoutes.security.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Безопасность'),
                ),
                GoRoute(
                  name: AppRoutes.billing.name,
                  path: AppRoutes.billing.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Тариф и оплата'),
                ),
                GoRoute(
                  name: AppRoutes.help.name,
                  path: AppRoutes.help.path,
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, _) =>
                      const RoutePlaceholderScreen(title: 'Помощь'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static List<RouteBase> _flowRoutes() {
    return <RouteBase>[
      // Top level so Today and Calendar can open it without switching the
      // shell to the Properties branch. The shell is declared first, so
      // `/properties/favorites` still matches inside the Properties tab.
      GoRoute(
        name: AppRoutes.property.name,
        path: AppRoutes.property.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Ваш объект'),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.propertyBookings.name,
            path: AppRoutes.propertyBookings.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Бронирования'),
          ),
          GoRoute(
            name: AppRoutes.propertySettings.name,
            path: AppRoutes.propertySettings.path,
            builder: (_, _) => const RoutePlaceholderScreen(title: 'Настройки'),
          ),
          GoRoute(
            name: AppRoutes.propertyReady.name,
            path: AppRoutes.propertyReady.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Квартира готова'),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.addProperty.name,
        path: AppRoutes.addProperty.path,
        builder: (_, _) =>
            const RoutePlaceholderScreen(title: 'Добавить квартиру'),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.addPropertyChannels.name,
            path: AppRoutes.addPropertyChannels.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Подключите площадки'),
          ),
          GoRoute(
            name: AppRoutes.addPropertyTerms.name,
            path: AppRoutes.addPropertyTerms.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Условия проживания'),
          ),
        ],
      ),
      // Declared before `/bookings/:bookingId` so `new` is not an id.
      GoRoute(
        name: AppRoutes.newBooking.name,
        path: AppRoutes.newBooking.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Новая бронь'),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.newBookingGuest.name,
            path: AppRoutes.newBookingGuest.path,
            builder: (_, _) => const RoutePlaceholderScreen(title: 'Гость'),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.booking.name,
        path: AppRoutes.booking.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Бронирование'),
      ),
      GoRoute(
        name: AppRoutes.contract.name,
        path: AppRoutes.contract.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Договор'),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.contractSend.name,
            path: AppRoutes.contractSend.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Отправка договора'),
          ),
          GoRoute(
            name: AppRoutes.contractStatus.name,
            path: AppRoutes.contractStatus.path,
            builder: (_, _) =>
                const RoutePlaceholderScreen(title: 'Статус договора'),
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.notifications.name,
        path: AppRoutes.notifications.path,
        builder: (_, _) => const RoutePlaceholderScreen(title: 'Уведомления'),
      ),
      GoRoute(
        name: AppRoutes.calendarConflict.name,
        path: AppRoutes.calendarConflict.path,
        builder: (_, _) =>
            const RoutePlaceholderScreen(title: 'Конфликт календарей'),
      ),
    ];
  }
}
