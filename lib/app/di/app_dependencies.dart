import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/api_config.dart';
import 'package:easy_booking/core/utils/network/dio_factory.dart';
import 'package:easy_booking/core/utils/network/interceptors/auth_interceptor.dart';
import 'package:easy_booking/core/utils/network/interceptors/error_interceptor.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';
import 'package:easy_booking/features/auth/data/repository/auth_repository_impl.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';
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

/// The single composition root.
///
/// Owns a private GetIt container, so nothing is reachable through a global
/// locator. The presentation layer resolves use cases with [getDep] through
/// `AppDependenciesProvider.of(context)`. Registrations are in dependency
/// order:
/// storage → session → clients → sources → repositories → use cases → router.
///
/// BLoCs are not registered: each screen creates its own in
/// `GoRouterWrapper.wrappedRoute` from the use cases resolved here.
final class AppDependencies {
  AppDependencies._(this._getIt);

  /// Wraps a container that already holds the use cases (and the router, if
  /// read), so tests can register fakes without [init].
  @visibleForTesting
  AppDependencies.fromContainer(GetIt getIt) : this._(getIt);

  final GetIt _getIt;

  /// Registers everything and waits for the asynchronous dependencies.
  /// Call once, before `runApp`.
  static Future<AppDependencies> init() async {
    final AppDependencies dependencies = AppDependencies._(
      GetIt.asNewInstance(),
    );
    dependencies
      .._registerStorage()
      .._registerSession()
      .._registerClients()
      .._registerSources()
      .._registerRepositories()
      .._registerUsecases()
      .._registerRouter();
    await dependencies._getIt.allReady();
    return dependencies;
  }

  /// The registered [T]. Screens resolve use cases only; repositories, data
  /// sources, storage, and clients are not for presentation.
  T getDep<T extends Object>() => _getIt<T>();

  void _registerStorage() {
    _getIt
      ..registerSingletonAsync<PreferencesStorage>(
        PreferencesStorageImpl.create,
      )
      ..registerLazySingleton<SecureStorage>(
        () => const SecureStorageImpl(storage: FlutterSecureStorage()),
      )
      ..registerLazySingleton<SessionStorage>(
        () => SessionStorageImpl(
          secureStorage: _getIt<SecureStorage>(),
          preferences: _getIt<PreferencesStorage>(),
        ),
      );
  }

  void _registerSession() {
    _getIt.registerSingletonAsync<AuthSession>(
      () async {
        final AuthSession session = AuthSession(
          sessionStorage: _getIt<SessionStorage>(),
        );
        await session.restore();
        return session;
      },
      dependsOn: <Type>[PreferencesStorage],
      dispose: (AuthSession session) => session.dispose(),
    );
  }

  void _registerClients() {
    _getIt.registerLazySingleton<ApiClient>(() {
      final ApiConfig config = ApiConfig.fromEnvironment();
      if (config.baseUrl.isEmpty) {
        AppLogger.warning(
          'API_BASE_URL is not set; pass it with --dart-define',
        );
      }
      return ApiClientImpl(
        dio: createDio(
          config: config,
          interceptors: <Interceptor>[
            AuthInterceptor(session: _getIt<AuthSession>()),
            // Last, so it sees the original error after `AuthInterceptor`.
            const ErrorInterceptor(),
          ],
        ),
      );
    }, dispose: (ApiClient client) => client.close());
  }

  void _registerSources() {
    _getIt
      ..registerLazySingleton<AuthRemote>(
        () => AuthRemoteImpl(apiClient: _getIt<ApiClient>()),
      )
      ..registerLazySingleton<HomeMockLocal>(
        () => const HomeMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so guest edits, sends, and drafts stay until restart.
      ..registerLazySingleton<ContractsMockLocal>(
        () => ContractsMockLocalImpl(now: DateTime.now),
      )
      ..registerLazySingleton<GuestsMockLocal>(
        () => const GuestsMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so read notifications stay read until restart.
      ..registerLazySingleton<NotificationsMockLocal>(
        () => NotificationsMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so profile edits, team, settings, and plan changes stay
      // until restart.
      ..registerLazySingleton<ProfileMockLocal>(
        () => ProfileMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so favorites, settings, the add-property draft, and
      // published properties stay until restart. One instance serves both
      // contracts, so a published property appears in the property list.
      ..registerLazySingleton<PropertyManagementMockLocal>(
        () => PropertiesMockLocalImpl(now: DateTime.now),
      )
      ..registerLazySingleton<PropertiesMockLocal>(
        () => _getIt<PropertyManagementMockLocal>(),
      )
      ..registerLazySingleton<CalendarMockLocal>(
        () => const CalendarMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so syncs and resolved conflicts last until restart.
      ..registerLazySingleton<CalendarSyncMockLocal>(
        () => CalendarSyncMockLocalImpl(now: DateTime.now),
      )
      // A singleton, so the draft, created and cancelled bookings stay until
      // restart.
      ..registerLazySingleton<BookingsMockLocal>(
        () => BookingsMockLocalImpl(now: DateTime.now),
      );
  }

  void _registerRepositories() {
    _getIt
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          remote: _getIt<AuthRemote>(),
          session: _getIt<AuthSession>(),
        ),
      )
      ..registerLazySingleton<HomeRepository>(
        () => HomeRepositoryImpl(local: _getIt<HomeMockLocal>()),
      )
      ..registerLazySingleton<ContractsRepository>(
        () => ContractsRepositoryImpl(local: _getIt<ContractsMockLocal>()),
      )
      ..registerLazySingleton<GuestsRepository>(
        () => GuestsRepositoryImpl(local: _getIt<GuestsMockLocal>()),
      )
      ..registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(
          local: _getIt<NotificationsMockLocal>(),
        ),
      )
      ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(local: _getIt<ProfileMockLocal>()),
      )
      ..registerLazySingleton<PropertiesRepository>(
        () => PropertiesRepositoryImpl(local: _getIt<PropertiesMockLocal>()),
      )
      ..registerLazySingleton<PropertyManagementRepository>(
        () => PropertyManagementRepositoryImpl(
          local: _getIt<PropertyManagementMockLocal>(),
        ),
      )
      ..registerLazySingleton<CalendarRepository>(
        () => CalendarRepositoryImpl(
          local: _getIt<CalendarMockLocal>(),
          properties: _getIt<PropertiesRepository>(),
        ),
      )
      ..registerLazySingleton<OccupancyRepository>(
        () => OccupancyRepositoryImpl(
          local: _getIt<CalendarSyncMockLocal>(),
          properties: _getIt<PropertiesRepository>(),
        ),
      )
      ..registerLazySingleton<ChannelsRepository>(
        () => ChannelsRepositoryImpl(local: _getIt<CalendarSyncMockLocal>()),
      )
      ..registerLazySingleton<CalendarConflictsRepository>(
        () => CalendarConflictsRepositoryImpl(
          local: _getIt<CalendarSyncMockLocal>(),
        ),
      )
      ..registerLazySingleton<BookingsRepository>(
        () => BookingsRepositoryImpl(
          local: _getIt<BookingsMockLocal>(),
          properties: _getIt<PropertiesRepository>(),
        ),
      );
  }

  void _registerUsecases() {
    _getIt
      ..registerLazySingleton<SendCodeUsecase>(
        () => SendCodeUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<VerifyCodeUsecase>(
        () => VerifyCodeUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<CreateAccountUsecase>(
        () => CreateAccountUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUsecase>(
        () => SignOutUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<GetHomeOverviewUsecase>(
        () => GetHomeOverviewUsecase(_getIt<HomeRepository>()),
      )
      ..registerLazySingleton<GetContractUsecase>(
        () => GetContractUsecase(_getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<UpdateContractGuestUsecase>(
        () => UpdateContractGuestUsecase(_getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<SendContractUsecase>(
        () => SendContractUsecase(_getIt<ContractsRepository>()),
      )
      ..registerLazySingleton<GetGuestDirectoryUsecase>(
        () => GetGuestDirectoryUsecase(_getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<GetGuestUsecase>(
        () => GetGuestUsecase(_getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<CreateGuestContractUsecase>(
        () => CreateGuestContractUsecase(_getIt<GuestsRepository>()),
      )
      ..registerLazySingleton<GetNotificationsUsecase>(
        () => GetNotificationsUsecase(_getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<MarkNotificationReadUsecase>(
        () => MarkNotificationReadUsecase(_getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<MarkAllNotificationsReadUsecase>(
        () =>
            MarkAllNotificationsReadUsecase(_getIt<NotificationsRepository>()),
      )
      ..registerLazySingleton<GetProfileUsecase>(
        () => GetProfileUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetProfileDetailsUsecase>(
        () => GetProfileDetailsUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<UpdateProfileUsecase>(
        () => UpdateProfileUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetTeamUsecase>(
        () => GetTeamUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<InviteTeamMemberUsecase>(
        () => InviteTeamMemberUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<RemoveTeamMemberUsecase>(
        () => RemoveTeamMemberUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetNotificationSettingsUsecase>(
        () => GetNotificationSettingsUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<UpdateNotificationSettingsUsecase>(
        () => UpdateNotificationSettingsUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetSecurityOverviewUsecase>(
        () => GetSecurityOverviewUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<SetBiometricLoginUsecase>(
        () => SetBiometricLoginUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<TerminateOtherSessionsUsecase>(
        () => TerminateOtherSessionsUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetBillingOverviewUsecase>(
        () => GetBillingOverviewUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<ChangeSubscriptionPlanUsecase>(
        () => ChangeSubscriptionPlanUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetHelpCenterUsecase>(
        () => GetHelpCenterUsecase(_getIt<ProfileRepository>()),
      )
      ..registerLazySingleton<GetPropertiesUsecase>(
        () => GetPropertiesUsecase(_getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<GetPropertyUsecase>(
        () => GetPropertyUsecase(_getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<SetPropertyFavoriteUsecase>(
        () => SetPropertyFavoriteUsecase(_getIt<PropertiesRepository>()),
      )
      ..registerLazySingleton<GetPropertyBookingsUsecase>(
        () =>
            GetPropertyBookingsUsecase(_getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetPropertySettingsUsecase>(
        () =>
            GetPropertySettingsUsecase(_getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<SavePropertySettingsUsecase>(
        () =>
            SavePropertySettingsUsecase(_getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetAddPropertyDraftUsecase>(
        () =>
            GetAddPropertyDraftUsecase(_getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<SaveAddPropertyDetailsUsecase>(
        () => SaveAddPropertyDetailsUsecase(
          _getIt<PropertyManagementRepository>(),
        ),
      )
      ..registerLazySingleton<SaveAddPropertyChannelsUsecase>(
        () => SaveAddPropertyChannelsUsecase(
          _getIt<PropertyManagementRepository>(),
        ),
      )
      ..registerLazySingleton<PublishPropertyUsecase>(
        () => PublishPropertyUsecase(_getIt<PropertyManagementRepository>()),
      )
      ..registerLazySingleton<GetCalendarDayUsecase>(
        () => GetCalendarDayUsecase(_getIt<CalendarRepository>()),
      )
      ..registerLazySingleton<GetOccupancyWeekUsecase>(
        () => GetOccupancyWeekUsecase(_getIt<OccupancyRepository>()),
      )
      ..registerLazySingleton<GetChannelsUsecase>(
        () => GetChannelsUsecase(_getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<GetChannelUsecase>(
        () => GetChannelUsecase(_getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<SyncChannelUsecase>(
        () => SyncChannelUsecase(_getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<DisconnectChannelUsecase>(
        () => DisconnectChannelUsecase(_getIt<ChannelsRepository>()),
      )
      ..registerLazySingleton<GetCalendarConflictUsecase>(
        () => GetCalendarConflictUsecase(_getIt<CalendarConflictsRepository>()),
      )
      ..registerLazySingleton<ResolveCalendarConflictUsecase>(
        () => ResolveCalendarConflictUsecase(
          _getIt<CalendarConflictsRepository>(),
        ),
      )
      ..registerLazySingleton<GetBookingUsecase>(
        () => GetBookingUsecase(_getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<CancelBookingUsecase>(
        () => CancelBookingUsecase(_getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<SearchBookingGuestsUsecase>(
        () => SearchBookingGuestsUsecase(_getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<GetBookingDraftUsecase>(
        () => GetBookingDraftUsecase(_getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<SaveBookingDraftUsecase>(
        () => SaveBookingDraftUsecase(_getIt<BookingsRepository>()),
      )
      ..registerLazySingleton<CreateBookingUsecase>(
        () => CreateBookingUsecase(_getIt<BookingsRepository>()),
      );
  }

  void _registerRouter() {
    _getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(session: _getIt<AuthSession>()),
      dispose: (GoRouter router) => router.dispose(),
    );
  }
}
