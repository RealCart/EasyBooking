import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/router/app_shell_screen.dart';
import 'package:easy_booking/app/router/route_not_found_screen.dart';
import 'package:easy_booking/app/router/route_placeholder_screen.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';
import 'package:easy_booking/features/auth/presentation/screens/account_setup_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/login_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/verify_code_screen.dart';

abstract final class AppRouter {
  /// Builds the app router. It re-evaluates redirects whenever [session]
  /// changes.
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
          isAccountSetupPending: session.isAccountSetupPending,
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

  /// Decides where the user may be:
  /// - signed out: only the login flow; other locations go to login with
  ///   the original location in [AppRoutes.fromQuery];
  /// - signed in with account setup pending: only account setup, carrying
  ///   `from` along;
  /// - signed in: the login flow and account setup go to `from` or today.
  ///
  /// Screens therefore never navigate after sign-in or account creation;
  /// they update the session and this redirect moves the user on.
  static String? redirect({
    required bool isAuthenticated,
    required bool isAccountSetupPending,
    required Uri uri,
  }) {
    final String path = uri.path;
    final bool isLoginFlow = _isLoginFlow(path);
    final bool isAccountSetup = path == AppRoutes.accountSetup.path;

    if (!isAuthenticated) {
      if (isLoginFlow) {
        return null;
      }
      return _withFrom(
        AppRoutes.login.path,
        safeFromLocation(uri.toString()),
      );
    }

    if (isAccountSetupPending) {
      if (isAccountSetup) {
        return null;
      }
      final String? from = isLoginFlow
          ? safeFromLocation(uri.queryParameters[AppRoutes.fromQuery])
          : safeFromLocation(uri.toString());
      return _withFrom(AppRoutes.accountSetup.path, from);
    }

    if (isLoginFlow || isAccountSetup) {
      return safeFromLocation(uri.queryParameters[AppRoutes.fromQuery]) ??
          AppRoutes.today.path;
    }
    return null;
  }

  /// Returns [from] when it is an in-app location worth returning to: not
  /// the login flow, not account setup, and not just the default tab.
  static String? safeFromLocation(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return null;
    }
    final String path = Uri.tryParse(from)?.path ?? '';
    if (path.isEmpty ||
        path == '/' ||
        path == AppRoutes.today.path ||
        path == AppRoutes.accountSetup.path ||
        _isLoginFlow(path)) {
      return null;
    }
    return from;
  }

  static bool _isLoginFlow(String path) {
    return path == AppRoutes.login.path ||
        path.startsWith('${AppRoutes.login.path}/');
  }

  static String _withFrom(String path, String? from) {
    return Uri(
      path: path,
      queryParameters: from == null
          ? null
          : <String, String>{AppRoutes.fromQuery: from},
    ).toString();
  }

  static List<RouteBase> _authRoutes() {
    return <RouteBase>[
      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        builder: (_, GoRouterState state) {
          return BlocProvider<LoginBloc>(
            create: (_) => GetIt.instance<LoginBloc>(),
            child: LoginScreen(
              from: state.uri.queryParameters[AppRoutes.fromQuery],
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.verifyCode.name,
            path: AppRoutes.verifyCode.path,
            redirect: (_, GoRouterState state) {
              if (_verifyCodePhone(state) != null) {
                return null;
              }
              return _withFrom(
                AppRoutes.login.path,
                state.uri.queryParameters[AppRoutes.fromQuery],
              );
            },
            builder: (_, GoRouterState state) {
              // The route redirect above guarantees a valid phone.
              final String phone = _verifyCodePhone(state)!;
              final Duration resendAfter = _verifyCodeResendAfter(state);
              return BlocProvider<VerifyCodeBloc>(
                create: (_) => GetIt.instance<VerifyCodeBloc>()
                  ..add(
                    VerifyCodeStarted(phone: phone, resendAfter: resendAfter),
                  ),
                child: VerifyCodeScreen(
                  phone: phone,
                  from: state.uri.queryParameters[AppRoutes.fromQuery],
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.accountSetup.name,
        path: AppRoutes.accountSetup.path,
        builder: (_, _) {
          return BlocProvider<AccountSetupBloc>(
            create: (_) => GetIt.instance<AccountSetupBloc>(),
            child: const AccountSetupScreen(),
          );
        },
      ),
    ];
  }

  /// The E.164 phone of the verify-code route, or `null` when it is missing
  /// or not a valid number.
  static String? _verifyCodePhone(GoRouterState state) {
    final String? phone = state.uri.queryParameters[AppRoutes.phoneQuery];
    return phone == null ? null : PhoneNumber.toE164(phone);
  }

  /// Resend delay of the verify-code route; zero when missing or invalid.
  static Duration _verifyCodeResendAfter(GoRouterState state) {
    final int? seconds = int.tryParse(
      state.uri.queryParameters[AppRoutes.resendAfterQuery] ?? '',
    );
    return Duration(seconds: seconds == null || seconds < 0 ? 0 : seconds);
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
