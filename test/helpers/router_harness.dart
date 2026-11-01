import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_bottom_navigation.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/features/auth/data/repository/auth_repository_impl.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:easy_booking/features/bookings/data/repository/bookings_repository_impl.dart';
import 'package:easy_booking/features/bookings/data/sources/local/bookings_mock_local.dart';
import 'package:easy_booking/features/bookings/domain/repository/bookings_repository.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/save_booking_draft_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/search_booking_guests_usecase.dart';
import 'package:easy_booking/features/calendar/data/repository/calendar_conflicts_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/repository/calendar_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/repository/channels_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/repository/occupancy_repository_impl.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_mock_local.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_conflicts_repository.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_repository.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';
import 'package:easy_booking/features/calendar/domain/repository/occupancy_repository.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_calendar_day_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_occupancy_week_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/resolve_calendar_conflict_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';
import 'package:easy_booking/features/contracts/data/repository/contracts_repository_impl.dart';
import 'package:easy_booking/features/contracts/data/sources/local/contracts_mock_local.dart';
import 'package:easy_booking/features/contracts/domain/repository/contracts_repository.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';
import 'package:easy_booking/features/guests/data/repository/guests_repository_impl.dart';
import 'package:easy_booking/features/guests/data/sources/local/guests_mock_local.dart';
import 'package:easy_booking/features/guests/domain/repository/guests_repository.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_directory_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';
import 'package:easy_booking/features/home/data/repository/home_repository_impl.dart';
import 'package:easy_booking/features/home/data/sources/local/home_mock_local.dart';
import 'package:easy_booking/features/home/domain/repository/home_repository.dart';
import 'package:easy_booking/features/home/domain/usecases/get_home_overview_usecase.dart';
import 'package:easy_booking/features/notifications/data/repository/notifications_repository_impl.dart';
import 'package:easy_booking/features/notifications/data/sources/local/notifications_mock_local.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';
import 'package:easy_booking/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:easy_booking/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:easy_booking/features/profile/data/repository/profile_repository_impl.dart';
import 'package:easy_booking/features/profile/data/sources/local/profile_mock_local.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:easy_booking/features/properties/data/repository/properties_repository_impl.dart';
import 'package:easy_booking/features/properties/data/repository/property_management_repository_impl.dart';
import 'package:easy_booking/features/properties/data/sources/local/properties_mock_local.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';
import 'package:easy_booking/features/properties/domain/repository/property_management_repository.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';

import 'fake_auth_remote.dart';
import 'fake_session_storage.dart';

const AuthTokens testTokens = AuthTokens(accessToken: 'access');

/// The clock of the home mock source: Thursday, 22 October 2026, as in the
/// design.
final DateTime homeTestNow = DateTime(2026, 10, 22, 8);

/// The real app router over an [AuthSession] backed by a fake storage.
///
/// The auth screens create their BLoCs from the use cases of
/// `AppDependenciesProvider`, so the harness provides [AppDependencies] over
/// an isolated GetIt with a real [AuthRepositoryImpl], a [FakeAuthRemote],
/// and the harness session. The container is reset in tear-down.
final class RouterHarness {
  RouterHarness._(
    this.tester,
    this.storage,
    this.session,
    this.remote,
    this.router,
  );

  final WidgetTester tester;
  final FakeSessionStorage storage;
  final AuthSession session;
  final FakeAuthRemote remote;
  final GoRouter router;

  /// Builds the app router and pumps it in a `MaterialApp.router`.
  ///
  /// The router, the session and the dependency container are disposed in
  /// tear-down.
  static Future<RouterHarness> pump(
    WidgetTester tester, {
    bool signedIn = true,
    bool accountSetupPending = false,
    String? initialLocation,
  }) async {
    final FakeSessionStorage storage = FakeSessionStorage();
    final AuthSession session = AuthSession(sessionStorage: storage);
    addTearDown(session.dispose);
    if (signedIn) {
      await session.signIn(
        testTokens,
        isAccountSetupPending: accountSetupPending,
      );
    }
    final FakeAuthRemote remote = FakeAuthRemote();
    final AppDependencies dependencies = authDependencies(
      session: session,
      remote: remote,
    );

    final GoRouter router = AppRouter.create(
      session: session,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      AppDependenciesProvider(
        dependencies: dependencies,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return RouterHarness._(tester, storage, session, remote, router);
  }

  /// [AppDependencies] with the auth repository and use cases, and every
  /// other feature's use cases over their mock sources (clocked at
  /// [homeTestNow]), registered as in `AppDependencies` in a new GetIt
  /// container, which is reset in tear-down.
  static AppDependencies authDependencies({
    required AuthSession session,
    required FakeAuthRemote remote,
  }) {
    final GetIt getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    getIt
      ..registerLazySingleton<HomeMockLocal>(
        () => HomeMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so guest edits, sends, and drafts stay until restart.
      ..registerLazySingleton<ContractsMockLocal>(
        () => ContractsMockLocalImpl(now: () => homeTestNow),
      )
      ..registerLazySingleton<GuestsMockLocal>(
        () => GuestsMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so read notifications stay read until restart.
      ..registerLazySingleton<NotificationsMockLocal>(
        () => NotificationsMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so profile edits, team, settings, and plan changes stay
      // until restart.
      ..registerLazySingleton<ProfileMockLocal>(
        () => ProfileMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so favorites, settings, the add-property draft, and
      // published properties stay until restart. One instance serves both
      // contracts, so a published property appears in the property list.
      ..registerLazySingleton<PropertyManagementMockLocal>(
        () => PropertiesMockLocalImpl(now: () => homeTestNow),
      )
      ..registerLazySingleton<PropertiesMockLocal>(
        () => getIt<PropertyManagementMockLocal>(),
      )
      ..registerLazySingleton<CalendarMockLocal>(
        () => CalendarMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so syncs and resolved conflicts last until restart.
      ..registerLazySingleton<CalendarSyncMockLocal>(
        () => CalendarSyncMockLocalImpl(now: () => homeTestNow),
      )
      // A singleton, so the draft, created and cancelled bookings stay until
      // restart.
      ..registerLazySingleton<BookingsMockLocal>(
        () => BookingsMockLocalImpl(now: () => homeTestNow),
      )
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remote: remote, session: session),
      )
      ..registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(local: getIt<HomeMockLocal>()),
      )
      ..registerLazySingleton<ContractsRepository>(
        () => ContractsRepositoryImpl(local: getIt<ContractsMockLocal>()),
      )
      ..registerLazySingleton<GuestsRepository>(
        () => GuestsRepositoryImpl(local: getIt<GuestsMockLocal>()),
      )
      ..registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(
          local: getIt<NotificationsMockLocal>(),
        ),
      )
      ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(local: getIt<ProfileMockLocal>()),
      )
      ..registerLazySingleton<PropertiesRepository>(
        () => PropertiesRepositoryImpl(local: getIt<PropertiesMockLocal>()),
      )
      ..registerLazySingleton<PropertyManagementRepository>(
        () => PropertyManagementRepositoryImpl(
          local: getIt<PropertyManagementMockLocal>(),
        ),
      )
      ..registerLazySingleton<CalendarRepository>(
        () => CalendarRepositoryImpl(
          local: getIt<CalendarMockLocal>(),
          properties: getIt<PropertiesRepository>(),
        ),
      )
      ..registerLazySingleton<OccupancyRepository>(
        () => OccupancyRepositoryImpl(
          local: getIt<CalendarSyncMockLocal>(),
          properties: getIt<PropertiesRepository>(),
        ),
      )
      ..registerLazySingleton<ChannelsRepository>(
        () => ChannelsRepositoryImpl(local: getIt<CalendarSyncMockLocal>()),
      )
      ..registerLazySingleton<CalendarConflictsRepository>(
        () => CalendarConflictsRepositoryImpl(
          local: getIt<CalendarSyncMockLocal>(),
        ),
      )
      ..registerLazySingleton<BookingsRepository>(
        () => BookingsRepositoryImpl(
          local: getIt<BookingsMockLocal>(),
          properties: getIt<PropertiesRepository>(),
        ),
      )
      ..registerLazySingleton<SendCodeUsecase>(
        () => SendCodeUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<VerifyCodeUsecase>(
        () => VerifyCodeUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<CreateAccountUsecase>(
        () => CreateAccountUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUsecase>(
        () => SignOutUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetHomeOverviewUsecase>(
        () => GetHomeOverviewUsecase(getIt<HomeRepository>()),
      )
      ..registerLazySingleton<GetContractUsecase>(
        () => GetContractUsecase(getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<UpdateContractGuestUsecase>(
        () => UpdateContractGuestUsecase(getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<SendContractUsecase>(
        () => SendContractUsecase(getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<GetGuestDirectoryUsecase>(
        () => GetGuestDirectoryUsecase(getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<GetGuestUsecase>(
        () => GetGuestUsecase(getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<CreateGuestContractUsecase>(
        () => CreateGuestContractUsecase(getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<GetNotificationsUsecase>(
        () => GetNotificationsUsecase(getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<MarkNotificationReadUsecase>(
        () => MarkNotificationReadUsecase(getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<MarkAllNotificationsReadUsecase>(
        () => MarkAllNotificationsReadUsecase(getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<GetProfileUsecase>(
        () => GetProfileUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetProfileDetailsUsecase>(
        () => GetProfileDetailsUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<UpdateProfileUsecase>(
        () => UpdateProfileUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetTeamUsecase>(
        () => GetTeamUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<InviteTeamMemberUsecase>(
        () => InviteTeamMemberUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<RemoveTeamMemberUsecase>(
        () => RemoveTeamMemberUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetNotificationSettingsUsecase>(
        () => GetNotificationSettingsUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<UpdateNotificationSettingsUsecase>(
        () => UpdateNotificationSettingsUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetSecurityOverviewUsecase>(
        () => GetSecurityOverviewUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<SetBiometricLoginUsecase>(
        () => SetBiometricLoginUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<TerminateOtherSessionsUsecase>(
        () => TerminateOtherSessionsUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetBillingOverviewUsecase>(
        () => GetBillingOverviewUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<ChangeSubscriptionPlanUsecase>(
        () => ChangeSubscriptionPlanUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetHelpCenterUsecase>(
        () => GetHelpCenterUsecase(getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetPropertiesUsecase>(
        () => GetPropertiesUsecase(getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<GetPropertyUsecase>(
        () => GetPropertyUsecase(getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<SetPropertyFavoriteUsecase>(
        () => SetPropertyFavoriteUsecase(getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<GetPropertyBookingsUsecase>(
        () => GetPropertyBookingsUsecase(getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetPropertySettingsUsecase>(
        () => GetPropertySettingsUsecase(getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<SavePropertySettingsUsecase>(
        () =>
            SavePropertySettingsUsecase(getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetAddPropertyDraftUsecase>(
        () => GetAddPropertyDraftUsecase(getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<SaveAddPropertyDetailsUsecase>(
        () => SaveAddPropertyDetailsUsecase(
          getIt<PropertyManagementRepository>(),
        ),
      )
      ..registerLazySingleton<SaveAddPropertyChannelsUsecase>(
        () => SaveAddPropertyChannelsUsecase(
          getIt<PropertyManagementRepository>(),
        ),
      )
      ..registerLazySingleton<PublishPropertyUsecase>(
        () => PublishPropertyUsecase(getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetCalendarDayUsecase>(
        () => GetCalendarDayUsecase(getIt<CalendarRepository>()),
      )
      ..registerLazySingleton<GetOccupancyWeekUsecase>(
        () => GetOccupancyWeekUsecase(getIt<OccupancyRepository>()),
      )
      ..registerLazySingleton<GetChannelsUsecase>(
        () => GetChannelsUsecase(getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<GetChannelUsecase>(
        () => GetChannelUsecase(getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<SyncChannelUsecase>(
        () => SyncChannelUsecase(getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<DisconnectChannelUsecase>(
        () => DisconnectChannelUsecase(getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<GetCalendarConflictUsecase>(
        () => GetCalendarConflictUsecase(getIt<CalendarConflictsRepository>()),
      )
      ..registerLazySingleton<ResolveCalendarConflictUsecase>(
        () => ResolveCalendarConflictUsecase(
          getIt<CalendarConflictsRepository>(),
        ),
      )
      ..registerLazySingleton<GetBookingUsecase>(
        () => GetBookingUsecase(getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<CancelBookingUsecase>(
        () => CancelBookingUsecase(getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<SearchBookingGuestsUsecase>(
        () => SearchBookingGuestsUsecase(getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<GetBookingDraftUsecase>(
        () => GetBookingDraftUsecase(getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<SaveBookingDraftUsecase>(
        () => SaveBookingDraftUsecase(getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<CreateBookingUsecase>(
        () => CreateBookingUsecase(getIt<BookingsRepository>()),
      );
    return AppDependencies.fromContainer(getIt);
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
