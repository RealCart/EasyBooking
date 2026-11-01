import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/router/app_shell_screen.dart';
import 'package:easy_booking/app/router/route_not_found_screen.dart';
import 'package:easy_booking/core/utils/extensions/go_router_extension.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/phone_number.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/features/auth/presentation/screens/account_setup_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/login_screen.dart';
import 'package:easy_booking/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:easy_booking/features/bookings/presentation/screens/booking_screen.dart';
import 'package:easy_booking/features/bookings/presentation/screens/new_booking_price_screen.dart';
import 'package:easy_booking/features/bookings/presentation/screens/new_booking_screen.dart';
import 'package:easy_booking/features/calendar/presentation/screens/calendar_conflict_screen.dart';
import 'package:easy_booking/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:easy_booking/features/calendar/presentation/screens/channel_screen.dart';
import 'package:easy_booking/features/calendar/presentation/screens/channels_screen.dart';
import 'package:easy_booking/features/calendar/presentation/screens/occupancy_screen.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_screen.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_send_screen.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_status_screen.dart';
import 'package:easy_booking/features/guests/presentation/screens/guest_screen.dart';
import 'package:easy_booking/features/guests/presentation/screens/guests_screen.dart';
import 'package:easy_booking/features/home/presentation/screens/home_screen.dart';
import 'package:easy_booking/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/billing_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/help_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/profile_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/security_screen.dart';
import 'package:easy_booking/features/profile/presentation/screens/team_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_channels_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_terms_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/favorite_properties_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/properties_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_bookings_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_ready_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/property_settings_screen.dart';

abstract final class AppRouter {
  static GoRouter create({
    required AuthSession session,
    String? initialLocation,
  }) {
    final GlobalKey<NavigatorState> rootNavigatorKey =
        GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation ?? AppRoutes.today.path,
      // refreshListenable: session,
      // redirect: (BuildContext context, GoRouterState state) {
      //   return redirect(
      //     isAuthenticated: session.isAuthenticated,
      //     isAccountSetupPending: session.isAccountSetupPending,
      //     uri: state.uri,
      //   );
      // },
      errorBuilder: (_, GoRouterState state) {
        AppLogger.warning(
          'Navigation failed for ${state.uri.path}',
          error: state.error,
        );
        return const RouteNotFoundScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.root.path,
          redirect: (_, _) => AppRoutes.today.path,
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.login.name,
          path: AppRoutes.login.path,
          wrappedBuilder: (_, GoRouterState state) {
            return LoginScreen(
              from: state.uri.queryParameters[AppRoutes.fromQuery],
            );
          },
          routes: <RouteBase>[
            GoRouteExtension.wrappedRoute(
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
              wrappedBuilder: (_, GoRouterState state) {
                // The route redirect above guarantees a valid phone.
                return VerifyCodeScreen(
                  phone: _verifyCodePhone(state)!,
                  resendAfter: _verifyCodeResendAfter(state),
                  from: state.uri.queryParameters[AppRoutes.fromQuery],
                );
              },
            ),
          ],
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.accountSetup.name,
          path: AppRoutes.accountSetup.path,
          wrappedBuilder: (_, _) => const AccountSetupScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, StatefulNavigationShell navigationShell) {
            return AppShellScreen(navigationShell: navigationShell);
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteExtension.wrappedRoute(
                  name: AppRoutes.today.name,
                  path: AppRoutes.today.path,
                  wrappedBuilder: (_, _) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteExtension.wrappedRoute(
                  name: AppRoutes.calendar.name,
                  path: AppRoutes.calendar.path,
                  wrappedBuilder: (_, _) => const CalendarScreen(),
                  routes: <RouteBase>[
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.occupancy.name,
                      path: AppRoutes.occupancy.path,
                      wrappedBuilder: (_, _) => const OccupancyScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.channels.name,
                      path: AppRoutes.channels.path,
                      wrappedBuilder: (_, _) => const ChannelsScreen(),
                      routes: <RouteBase>[
                        GoRouteExtension.wrappedRoute(
                          name: AppRoutes.channel.name,
                          path: AppRoutes.channel.path,
                          parentNavigatorKey: rootNavigatorKey,
                          // The path pattern guarantees the id.
                          wrappedBuilder: (_, GoRouterState state) =>
                              ChannelScreen(
                                channelId: state
                                    .pathParameters[AppRoutes.channelIdParam]!,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteExtension.wrappedRoute(
                  name: AppRoutes.properties.name,
                  path: AppRoutes.properties.path,
                  wrappedBuilder: (_, _) => const PropertiesScreen(),
                  routes: <RouteBase>[
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.favoriteProperties.name,
                      path: AppRoutes.favoriteProperties.path,
                      wrappedBuilder: (_, _) =>
                          const FavoritePropertiesScreen(),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRouteExtension.wrappedRoute(
                  name: AppRoutes.profile.name,
                  path: AppRoutes.profile.path,
                  wrappedBuilder: (_, _) => const ProfileScreen(),
                  routes: <RouteBase>[
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.editProfile.name,
                      path: AppRoutes.editProfile.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) => const EditProfileScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.guests.name,
                      path: AppRoutes.guests.path,
                      wrappedBuilder: (_, _) => const GuestsScreen(),
                      routes: <RouteBase>[
                        GoRouteExtension.wrappedRoute(
                          name: AppRoutes.guest.name,
                          path: AppRoutes.guest.path,
                          parentNavigatorKey: rootNavigatorKey,
                          wrappedBuilder: (_, GoRouterState state) =>
                              GuestScreen(
                                guestId: state
                                    .pathParameters[AppRoutes.guestIdParam]!,
                              ),
                        ),
                      ],
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.team.name,
                      path: AppRoutes.team.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) => const TeamScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.notificationSettings.name,
                      path: AppRoutes.notificationSettings.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) =>
                          const NotificationSettingsScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.security.name,
                      path: AppRoutes.security.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) => const SecurityScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.billing.name,
                      path: AppRoutes.billing.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) => const BillingScreen(),
                    ),
                    GoRouteExtension.wrappedRoute(
                      name: AppRoutes.help.name,
                      path: AppRoutes.help.path,
                      parentNavigatorKey: rootNavigatorKey,
                      wrappedBuilder: (_, _) => const HelpScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.property.name,
          path: AppRoutes.property.path,
          // The path pattern guarantees the id.
          wrappedBuilder: (_, GoRouterState state) => PropertyScreen(
            propertyId: state.pathParameters[AppRoutes.propertyIdParam]!,
          ),
          routes: <RouteBase>[
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.propertyBookings.name,
              path: AppRoutes.propertyBookings.path,
              // The parent's path pattern guarantees the id.
              wrappedBuilder: (_, GoRouterState state) =>
                  PropertyBookingsScreen(
                    propertyId:
                        state.pathParameters[AppRoutes.propertyIdParam]!,
                  ),
            ),
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.propertySettings.name,
              path: AppRoutes.propertySettings.path,
              wrappedBuilder: (_, GoRouterState state) =>
                  PropertySettingsScreen(
                    propertyId:
                        state.pathParameters[AppRoutes.propertyIdParam]!,
                  ),
            ),
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.propertyReady.name,
              path: AppRoutes.propertyReady.path,
              wrappedBuilder: (_, GoRouterState state) => PropertyReadyScreen(
                propertyId: state.pathParameters[AppRoutes.propertyIdParam]!,
              ),
            ),
          ],
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.addProperty.name,
          path: AppRoutes.addProperty.path,
          wrappedBuilder: (_, _) => const AddPropertyScreen(),
          routes: <RouteBase>[
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.addPropertyChannels.name,
              path: AppRoutes.addPropertyChannels.path,
              wrappedBuilder: (_, _) => const AddPropertyChannelsScreen(),
            ),
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.addPropertyTerms.name,
              path: AppRoutes.addPropertyTerms.path,
              wrappedBuilder: (_, _) => const AddPropertyTermsScreen(),
            ),
          ],
        ),
        // Declared before `/bookings/:bookingId` so `new` is not an id.
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.newBooking.name,
          path: AppRoutes.newBooking.path,
          wrappedBuilder: (_, _) => const NewBookingScreen(),
          routes: <RouteBase>[
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.newBookingGuest.name,
              path: AppRoutes.newBookingGuest.path,
              wrappedBuilder: (_, _) => const NewBookingPriceScreen(),
            ),
          ],
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.booking.name,
          path: AppRoutes.booking.path,
          // The path pattern guarantees the id.
          wrappedBuilder: (_, GoRouterState state) => BookingScreen(
            bookingId: state.pathParameters[AppRoutes.bookingIdParam]!,
          ),
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.contract.name,
          path: AppRoutes.contract.path,
          wrappedBuilder: (_, GoRouterState state) => ContractScreen(
            contractId: state.pathParameters[AppRoutes.contractIdParam]!,
          ),
          routes: <RouteBase>[
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.contractSend.name,
              path: AppRoutes.contractSend.path,
              wrappedBuilder: (_, GoRouterState state) => ContractSendScreen(
                contractId: state.pathParameters[AppRoutes.contractIdParam]!,
              ),
            ),
            GoRouteExtension.wrappedRoute(
              name: AppRoutes.contractStatus.name,
              path: AppRoutes.contractStatus.path,
              wrappedBuilder: (_, GoRouterState state) => ContractStatusScreen(
                contractId: state.pathParameters[AppRoutes.contractIdParam]!,
              ),
            ),
          ],
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.notifications.name,
          path: AppRoutes.notifications.path,
          wrappedBuilder: (_, _) => const NotificationsScreen(),
        ),
        GoRouteExtension.wrappedRoute(
          name: AppRoutes.calendarConflict.name,
          path: AppRoutes.calendarConflict.path,
          // The path pattern guarantees the id.
          wrappedBuilder: (_, GoRouterState state) => CalendarConflictScreen(
            conflictId: state.pathParameters[AppRoutes.conflictIdParam]!,
          ),
        ),
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
        path == AppRoutes.root.path ||
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
}
