import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invoice_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/payment_card_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/plan_usage_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Thursday, 22 October 2026, 14:00: the fixed clock of the profile tests.
final DateTime profileTestNow = DateTime(2026, 10, 22, 14);

const ProfileEntity testProfile = ProfileEntity(
  firstName: 'Бексултан',
  lastName: 'Нишанбек',
  role: ProfileRole.owner,
  city: 'Алматы',
  propertyCount: 4,
  teamMemberCount: 2,
  plan: SubscriptionPlan.pro,
);

const ProfileDetailsEntity testProfileDetails = ProfileDetailsEntity(
  firstName: 'Бексултан',
  lastName: 'Нишанбек',
  phone: '+77012345678',
  email: 'b.nishanbek@gmail.com',
  teamName: 'EasyBooking Алматы',
  city: KazakhstanCities.almaty,
);

const TeamMemberEntity testOwner = TeamMemberEntity(
  id: 'member-owner',
  firstName: 'Бексултан',
  lastName: 'Нишанбек',
  phone: '+77012345678',
  role: ProfileRole.owner,
  propertyCount: 4,
  hasAllProperties: true,
  isCurrentUser: true,
);

const TeamMemberEntity testManager = TeamMemberEntity(
  id: 'member-aliya',
  firstName: 'Алия',
  lastName: 'Жумабек',
  phone: '+77015550142',
  role: ProfileRole.manager,
  propertyCount: 4,
  hasAllProperties: false,
  isCurrentUser: false,
);

const TeamMemberEntity testCleaner = TeamMemberEntity(
  id: 'member-aigerim',
  firstName: 'Айгерим',
  lastName: 'Касым',
  phone: '+77075550318',
  role: ProfileRole.cleaner,
  propertyCount: 2,
  hasAllProperties: false,
  isCurrentUser: false,
);

/// The owner, Алия (manager), and Айгерим (cleaner).
const List<TeamMemberEntity> testTeam = <TeamMemberEntity>[
  testOwner,
  testManager,
  testCleaner,
];

const NotificationSettingsEntity testNotificationSettings =
    NotificationSettingsEntity(
      enabledTopics: <NotificationTopic>{
        NotificationTopic.newBooking,
        NotificationTopic.checkInOut,
      },
      channels: <NotificationDeliveryChannel>{NotificationDeliveryChannel.push},
    );

/// This iPhone and, unless [hasOtherSession] is false, a MacBook Air; a
/// sign-in at 09:41 on 22 October and the app code change of 3 September.
/// [receivedAt], the source's time, defaults to [profileTestNow].
SecurityOverviewEntity testSecurityOverview({
  bool isBiometricLoginEnabled = true,
  bool hasOtherSession = true,
  DateTime? receivedAt,
}) {
  return SecurityOverviewEntity(
    phone: '+77012345678',
    isPhoneVerified: true,
    appCodeChangedAt: DateTime(2026, 9, 3, 18, 20),
    isBiometricLoginEnabled: isBiometricLoginEnabled,
    sessions: <ActiveSessionEntity>[
      ActiveSessionEntity(
        id: 'session-iphone',
        deviceName: 'iPhone 15 Pro',
        deviceType: SessionDeviceType.phone,
        city: 'Алматы',
        lastActiveAt: profileTestNow,
        isCurrent: true,
      ),
      if (hasOtherSession)
        ActiveSessionEntity(
          id: 'session-macbook',
          deviceName: 'MacBook Air',
          deviceType: SessionDeviceType.computer,
          city: 'Алматы',
          lastActiveAt: DateTime(2026, 10, 17, 21, 14),
          isCurrent: false,
        ),
    ],
    recentEvents: <SecurityEventEntity>[
      SecurityEventEntity(
        id: 'event-signed-in',
        kind: SecurityEventKind.signedIn,
        occurredAt: DateTime(2026, 10, 22, 9, 41),
        deviceName: 'iPhone',
      ),
      SecurityEventEntity(
        id: 'event-app-code-changed',
        kind: SecurityEventKind.appCodeChanged,
        occurredAt: DateTime(2026, 9, 3, 18, 20),
      ),
    ],
    receivedAt: receivedAt ?? profileTestNow,
  );
}

/// Pro at 3 990 ₸, 4 of 10 properties and [memberCount] of 5 members.
BillingOverviewEntity testBillingOverview({
  SubscriptionPlan plan = SubscriptionPlan.pro,
  int memberCount = 3,
}) {
  final bool isPro = plan == SubscriptionPlan.pro;
  return BillingOverviewEntity(
    plan: plan,
    isActive: true,
    monthlyPrice: isPro ? 3990 : 0,
    nextChargeAt: isPro ? DateTime(2026, 11, 15) : null,
    propertyUsage: PlanUsageEntity(used: 4, limit: isPro ? 10 : 5),
    memberUsage: PlanUsageEntity(used: memberCount, limit: isPro ? 5 : 2),
    includedFeatures: isPro
        ? const <String>['Договоры с электронной подписью']
        : const <String>[],
    paymentCard: const PaymentCardEntity(
      brand: PaymentCardBrand.visa,
      lastDigits: '4218',
    ),
    latestInvoice: InvoiceEntity(
      id: 'invoice-2026-10',
      period: DateTime(2026, 10),
      amount: 3990,
    ),
  );
}

const HelpCenterEntity testHelpCenter = HelpCenterEntity(
  support: SupportContactEntity(
    name: 'Поддержка EasyBooking',
    typicalResponseTime: Duration(minutes: 10),
    isOnline: true,
  ),
  topics: <HelpTopicEntity>[
    HelpTopicEntity(
      id: 'calendar-sync',
      title: 'Синхронизация календарей',
      summary: 'iCal, ошибки и частота обновлений',
    ),
    HelpTopicEntity(
      id: 'billing',
      title: 'Оплата и тариф',
      summary: 'Счета, карты и лимиты',
    ),
  ],
  guides: <HelpGuideEntity>[
    HelpGuideEntity(
      id: 'connect-airbnb',
      title: 'Как подключить Airbnb',
      readingTime: Duration(minutes: 4),
    ),
  ],
);

/// [ProfileRepository] with settable results that records every call.
///
/// Set a `hold...` flag to keep the next requests of that kind pending;
/// each gets a completer in the matching `held...` list.
final class FakeProfileRepository implements ProfileRepository {
  Either<Failure, ProfileEntity> profileResult =
      const Right<Failure, ProfileEntity>(testProfile);
  Either<Failure, ProfileDetailsEntity> detailsResult =
      const Right<Failure, ProfileDetailsEntity>(testProfileDetails);
  Either<Failure, ProfileDetailsEntity> updateProfileResult =
      const Right<Failure, ProfileDetailsEntity>(testProfileDetails);
  Either<Failure, List<TeamMemberEntity>> teamResult =
      const Right<Failure, List<TeamMemberEntity>>(testTeam);
  Either<Failure, List<TeamMemberEntity>> inviteResult =
      const Right<Failure, List<TeamMemberEntity>>(testTeam);
  Either<Failure, List<TeamMemberEntity>> removeResult =
      const Right<Failure, List<TeamMemberEntity>>(testTeam);
  Either<Failure, NotificationSettingsEntity> notificationSettingsResult =
      const Right<Failure, NotificationSettingsEntity>(
        testNotificationSettings,
      );
  Either<Failure, NotificationSettingsEntity> updateNotificationSettingsResult =
      const Right<Failure, NotificationSettingsEntity>(
        testNotificationSettings,
      );
  Either<Failure, SecurityOverviewEntity> securityResult =
      Right<Failure, SecurityOverviewEntity>(testSecurityOverview());
  Either<Failure, SecurityOverviewEntity> biometricResult =
      Right<Failure, SecurityOverviewEntity>(testSecurityOverview());
  Either<Failure, SecurityOverviewEntity> terminateResult =
      Right<Failure, SecurityOverviewEntity>(
        testSecurityOverview(hasOtherSession: false),
      );
  Either<Failure, BillingOverviewEntity> billingResult =
      Right<Failure, BillingOverviewEntity>(testBillingOverview());
  Either<Failure, BillingOverviewEntity> changePlanResult =
      Right<Failure, BillingOverviewEntity>(testBillingOverview());
  Either<Failure, HelpCenterEntity> helpResult =
      const Right<Failure, HelpCenterEntity>(testHelpCenter);

  bool holdDetails = false;
  bool holdUpdateProfile = false;
  bool holdTeam = false;
  bool holdInvite = false;
  bool holdRemove = false;
  bool holdNotificationSettings = false;
  bool holdUpdateNotificationSettings = false;
  bool holdSecurity = false;
  bool holdBiometric = false;
  bool holdTerminate = false;
  bool holdBilling = false;
  bool holdChangePlan = false;
  bool holdHelp = false;

  final List<Completer<Either<Failure, ProfileDetailsEntity>>> heldDetails =
      <Completer<Either<Failure, ProfileDetailsEntity>>>[];
  final List<Completer<Either<Failure, ProfileDetailsEntity>>>
  heldUpdateProfile = <Completer<Either<Failure, ProfileDetailsEntity>>>[];
  final List<Completer<Either<Failure, List<TeamMemberEntity>>>> heldTeam =
      <Completer<Either<Failure, List<TeamMemberEntity>>>>[];
  final List<Completer<Either<Failure, List<TeamMemberEntity>>>> heldInvite =
      <Completer<Either<Failure, List<TeamMemberEntity>>>>[];
  final List<Completer<Either<Failure, List<TeamMemberEntity>>>> heldRemove =
      <Completer<Either<Failure, List<TeamMemberEntity>>>>[];
  final List<Completer<Either<Failure, NotificationSettingsEntity>>>
  heldNotificationSettings =
      <Completer<Either<Failure, NotificationSettingsEntity>>>[];
  final List<Completer<Either<Failure, NotificationSettingsEntity>>>
  heldUpdateNotificationSettings =
      <Completer<Either<Failure, NotificationSettingsEntity>>>[];
  final List<Completer<Either<Failure, SecurityOverviewEntity>>> heldSecurity =
      <Completer<Either<Failure, SecurityOverviewEntity>>>[];
  final List<Completer<Either<Failure, SecurityOverviewEntity>>> heldBiometric =
      <Completer<Either<Failure, SecurityOverviewEntity>>>[];
  final List<Completer<Either<Failure, SecurityOverviewEntity>>> heldTerminate =
      <Completer<Either<Failure, SecurityOverviewEntity>>>[];
  final List<Completer<Either<Failure, BillingOverviewEntity>>> heldBilling =
      <Completer<Either<Failure, BillingOverviewEntity>>>[];
  final List<Completer<Either<Failure, BillingOverviewEntity>>> heldChangePlan =
      <Completer<Either<Failure, BillingOverviewEntity>>>[];
  final List<Completer<Either<Failure, HelpCenterEntity>>> heldHelp =
      <Completer<Either<Failure, HelpCenterEntity>>>[];

  int profileCount = 0;
  int detailsCount = 0;
  int teamCount = 0;
  int notificationSettingsCount = 0;
  int securityCount = 0;
  int terminateCount = 0;
  int billingCount = 0;
  int helpCount = 0;

  final List<UpdateProfileParamsEntity> updateProfileParams =
      <UpdateProfileParamsEntity>[];
  final List<InviteTeamMemberParamsEntity> inviteParams =
      <InviteTeamMemberParamsEntity>[];
  final List<String> removedMemberIds = <String>[];
  final List<UpdateNotificationSettingsParamsEntity>
  updateNotificationSettingsParams = <UpdateNotificationSettingsParamsEntity>[];
  final List<bool> biometricValues = <bool>[];
  final List<SubscriptionPlan> changedPlans = <SubscriptionPlan>[];

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    profileCount += 1;
    return profileResult;
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> getProfileDetails() {
    detailsCount += 1;
    return _answer(holdDetails, heldDetails, detailsResult);
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  ) {
    updateProfileParams.add(params);
    return _answer(holdUpdateProfile, heldUpdateProfile, updateProfileResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> getTeam() {
    teamCount += 1;
    return _answer(holdTeam, heldTeam, teamResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  ) {
    inviteParams.add(params);
    return _answer(holdInvite, heldInvite, inviteResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  ) {
    removedMemberIds.add(memberId);
    return _answer(holdRemove, heldRemove, removeResult);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  getNotificationSettings() {
    notificationSettingsCount += 1;
    return _answer(
      holdNotificationSettings,
      heldNotificationSettings,
      notificationSettingsResult,
    );
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(UpdateNotificationSettingsParamsEntity params) {
    updateNotificationSettingsParams.add(params);
    return _answer(
      holdUpdateNotificationSettings,
      heldUpdateNotificationSettings,
      updateNotificationSettingsResult,
    );
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> getSecurityOverview() {
    securityCount += 1;
    return _answer(holdSecurity, heldSecurity, securityResult);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  }) {
    biometricValues.add(isEnabled);
    return _answer(holdBiometric, heldBiometric, biometricResult);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> terminateOtherSessions() {
    terminateCount += 1;
    return _answer(holdTerminate, heldTerminate, terminateResult);
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> getBillingOverview() {
    billingCount += 1;
    return _answer(holdBilling, heldBilling, billingResult);
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  ) {
    changedPlans.add(plan);
    return _answer(holdChangePlan, heldChangePlan, changePlanResult);
  }

  @override
  Future<Either<Failure, HelpCenterEntity>> getHelpCenter() {
    helpCount += 1;
    return _answer(holdHelp, heldHelp, helpResult);
  }

  static Future<T> _answer<T>(bool hold, List<Completer<T>> held, T result) {
    if (!hold) {
      return Future<T>.value(result);
    }
    final Completer<T> completer = Completer<T>();
    held.add(completer);
    return completer.future;
  }
}
