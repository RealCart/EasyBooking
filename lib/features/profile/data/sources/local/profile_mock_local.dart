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
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';

/// The sample profile, team, settings, and subscription from the design
/// until the profile API exists.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Writes change in-memory state, so they
/// last until the app restarts and every later read sees them (an edited
/// name shows on «Профиль», an invited member raises the team count). It
/// also enforces what the server would: plan limits, a unique phone per
/// team, and an irremovable owner. Replace it with a `ProfileRemote`
/// returning models when the endpoints are ready.
abstract interface class ProfileMockLocal {
  Future<Either<Failure, ProfileEntity>> loadProfile();

  Future<Either<Failure, ProfileDetailsEntity>> loadProfileDetails();

  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  );

  Future<Either<Failure, List<TeamMemberEntity>>> loadTeam();

  /// [params] holds an E.164 phone.
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  );

  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  );

  Future<Either<Failure, NotificationSettingsEntity>>
  loadNotificationSettings();

  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(UpdateNotificationSettingsParamsEntity params);

  Future<Either<Failure, SecurityOverviewEntity>> loadSecurityOverview();

  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  });

  Future<Either<Failure, SecurityOverviewEntity>> terminateOtherSessions();

  Future<Either<Failure, BillingOverviewEntity>> loadBillingOverview();

  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  );

  Future<Either<Failure, HelpCenterEntity>> loadHelpCenter();
}

final class ProfileMockLocalImpl implements ProfileMockLocal {
  /// [now] supplies the current time, so sessions, invitations, and charges
  /// are relative to today.
  ProfileMockLocalImpl({required this._now});

  static const String ownerId = 'member-owner';
  static const String managerId = 'member-aliya';
  static const String cleanerId = 'member-aigerim';
  static const String currentSessionId = 'session-iphone';
  static const String laptopSessionId = 'session-macbook';

  /// Properties of the sample workspace, as in the properties mock.
  static const int _propertyCount = 4;

  static const Map<SubscriptionPlan, _PlanTerms> _planTerms =
      <SubscriptionPlan, _PlanTerms>{
        SubscriptionPlan.free: _PlanTerms(
          monthlyPrice: 0,
          propertyLimit: 5,
          memberLimit: 2,
          features: <String>[
            'Синхронизация Airbnb и Booking.com',
            'До 5 объектов и 2 участников',
          ],
        ),
        SubscriptionPlan.pro: _PlanTerms(
          monthlyPrice: 3990,
          propertyLimit: 10,
          memberLimit: 5,
          features: <String>[
            'Синхронизация Airbnb и Booking.com',
            'Договоры с электронной подписью',
            'До 10 объектов и 5 участников',
            'Приоритетная поддержка',
          ],
        ),
      };

  final DateTime Function() _now;

  ProfileDetailsEntity _details = const ProfileDetailsEntity(
    firstName: 'Бексултан',
    lastName: 'Нишанбек',
    phone: '+77012345678',
    email: 'b.nishanbek@gmail.com',
    teamName: 'EasyBooking Алматы',
    city: KazakhstanCities.almaty,
  );

  List<TeamMemberEntity> _members = const <TeamMemberEntity>[
    TeamMemberEntity(
      id: ownerId,
      firstName: 'Бексултан',
      lastName: 'Нишанбек',
      phone: '+77012345678',
      role: ProfileRole.owner,
      propertyCount: _propertyCount,
      hasAllProperties: true,
      isCurrentUser: true,
    ),
    TeamMemberEntity(
      id: managerId,
      firstName: 'Алия',
      lastName: 'Жумабек',
      phone: '+77015550142',
      role: ProfileRole.manager,
      propertyCount: 4,
      hasAllProperties: false,
      isCurrentUser: false,
    ),
    TeamMemberEntity(
      id: cleanerId,
      firstName: 'Айгерим',
      lastName: 'Касым',
      phone: '+77075550318',
      role: ProfileRole.cleaner,
      propertyCount: 2,
      hasAllProperties: false,
      isCurrentUser: false,
    ),
  ];

  int _invitedCount = 0;

  NotificationSettingsEntity _notificationSettings =
      const NotificationSettingsEntity(
        enabledTopics: <NotificationTopic>{
          NotificationTopic.newBooking,
          NotificationTopic.checkInOut,
          NotificationTopic.contractAwaitingSignature,
          NotificationTopic.contractSigned,
          NotificationTopic.channelError,
        },
        channels: <NotificationDeliveryChannel>{
          NotificationDeliveryChannel.push,
        },
      );

  bool _isBiometricLoginEnabled = true;

  /// Set once «Завершить другие сеансы» ran.
  DateTime? _otherSessionsTerminatedAt;

  SubscriptionPlan _plan = SubscriptionPlan.pro;

  @override
  Future<Either<Failure, ProfileEntity>> loadProfile() async {
    final TeamMemberEntity owner = _members.firstWhere(
      (TeamMemberEntity member) => member.isCurrentUser,
    );
    return Right<Failure, ProfileEntity>(
      ProfileEntity(
        firstName: _details.firstName,
        lastName: _details.lastName,
        role: owner.role,
        city: _details.city.name,
        propertyCount: _propertyCount,
        teamMemberCount: _members.length - 1,
        plan: _plan,
      ),
    );
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> loadProfileDetails() async {
    return Right<Failure, ProfileDetailsEntity>(_details);
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  ) async {
    _details = ProfileDetailsEntity(
      firstName: params.firstName,
      lastName: params.lastName,
      phone: _details.phone,
      email: params.email,
      teamName: params.teamName,
      city: params.city,
    );
    _members = List<TeamMemberEntity>.unmodifiable(
      _members.map(
        (TeamMemberEntity member) => member.isCurrentUser
            ? _withName(
                member,
                firstName: params.firstName,
                lastName: params.lastName,
              )
            : member,
      ),
    );
    return Right<Failure, ProfileDetailsEntity>(_details);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> loadTeam() async {
    return Right<Failure, List<TeamMemberEntity>>(_members);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  ) async {
    if (params.role == ProfileRole.owner) {
      return const Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(code: ProfileErrorCodes.ownerRoleNotAssignable),
      );
    }
    final bool isMember = _members.any(
      (TeamMemberEntity member) => member.phone == params.phone,
    );
    if (isMember) {
      return const Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(
          fieldErrors: <String, String>{
            ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
          },
        ),
      );
    }
    if (_members.length >= _planTerms[_plan]!.memberLimit) {
      return const Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(code: ProfileErrorCodes.teamLimitReached),
      );
    }

    _invitedCount += 1;
    _members = List<TeamMemberEntity>.unmodifiable(<TeamMemberEntity>[
      ..._members,
      TeamMemberEntity(
        id: 'member-invited-$_invitedCount',
        firstName: params.firstName,
        lastName: params.lastName,
        phone: params.phone,
        role: params.role,
        propertyCount: 0,
        hasAllProperties: false,
        isCurrentUser: false,
        status: TeamMemberStatus.invited,
        // «Приглашение действует 72 часа».
        inviteExpiresAt: _now().add(const Duration(hours: 72)),
      ),
    ]);
    return Right<Failure, List<TeamMemberEntity>>(_members);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  ) async {
    final int index = _members.indexWhere(
      (TeamMemberEntity member) => member.id == memberId,
    );
    if (index == -1) {
      return Left<Failure, List<TeamMemberEntity>>(
        ServerFailure(statusCode: 404, message: 'Unknown member $memberId'),
      );
    }
    final TeamMemberEntity member = _members[index];
    if (member.isCurrentUser || member.role == ProfileRole.owner) {
      return const Left<Failure, List<TeamMemberEntity>>(
        ValidationFailure(code: ProfileErrorCodes.cannotRemoveOwner),
      );
    }
    _members = List<TeamMemberEntity>.unmodifiable(
      List<TeamMemberEntity>.of(_members)..removeAt(index),
    );
    return Right<Failure, List<TeamMemberEntity>>(_members);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  loadNotificationSettings() async {
    return Right<Failure, NotificationSettingsEntity>(_notificationSettings);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(
    UpdateNotificationSettingsParamsEntity params,
  ) async {
    if (params.channels.isEmpty) {
      return const Left<Failure, NotificationSettingsEntity>(
        ValidationFailure(code: ProfileErrorCodes.noDeliveryChannel),
      );
    }
    _notificationSettings = NotificationSettingsEntity(
      enabledTopics: Set<NotificationTopic>.unmodifiable(params.enabledTopics),
      channels: Set<NotificationDeliveryChannel>.unmodifiable(params.channels),
    );
    return Right<Failure, NotificationSettingsEntity>(_notificationSettings);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> loadSecurityOverview() async {
    return Right<Failure, SecurityOverviewEntity>(_securityOverview());
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  }) async {
    _isBiometricLoginEnabled = isEnabled;
    return Right<Failure, SecurityOverviewEntity>(_securityOverview());
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>>
  terminateOtherSessions() async {
    _otherSessionsTerminatedAt ??= _now();
    return Right<Failure, SecurityOverviewEntity>(_securityOverview());
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> loadBillingOverview() async {
    return Right<Failure, BillingOverviewEntity>(_billingOverview());
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  ) async {
    final _PlanTerms terms = _planTerms[plan]!;
    if (_propertyCount > terms.propertyLimit ||
        _members.length > terms.memberLimit) {
      return const Left<Failure, BillingOverviewEntity>(
        ValidationFailure(code: ProfileErrorCodes.planLimitExceeded),
      );
    }
    _plan = plan;
    return Right<Failure, BillingOverviewEntity>(_billingOverview());
  }

  @override
  Future<Either<Failure, HelpCenterEntity>> loadHelpCenter() async {
    return const Right<Failure, HelpCenterEntity>(
      HelpCenterEntity(
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
            id: 'bookings',
            title: 'Бронирования и конфликты',
            summary: 'Ручные брони и пересечения',
          ),
          HelpTopicEntity(
            id: 'contracts',
            title: 'Договоры и подпись',
            summary: 'Документы гостя и статусы',
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
          HelpGuideEntity(
            id: 'first-contract',
            title: 'Первый договор с гостем',
            readingTime: Duration(minutes: 6),
          ),
        ],
      ),
    );
  }

  SecurityOverviewEntity _securityOverview() {
    final DateTime now = _now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    // «Сегодня, 09:41», unless it is earlier than that today.
    final DateTime morning = today.add(const Duration(hours: 9, minutes: 41));
    final DateTime signedInAt = morning.isAfter(now) ? now : morning;
    final DateTime appCodeChangedAt = DateTime(
      now.year,
      now.month,
      now.day - 49,
      18,
      20,
    );
    final DateTime? terminatedAt = _otherSessionsTerminatedAt;

    return SecurityOverviewEntity(
      phone: _details.phone,
      isPhoneVerified: true,
      appCodeChangedAt: appCodeChangedAt,
      isBiometricLoginEnabled: _isBiometricLoginEnabled,
      sessions: List<ActiveSessionEntity>.unmodifiable(<ActiveSessionEntity>[
        ActiveSessionEntity(
          id: currentSessionId,
          deviceName: 'iPhone 15 Pro',
          deviceType: SessionDeviceType.phone,
          city: 'Алматы',
          lastActiveAt: now,
          isCurrent: true,
        ),
        if (terminatedAt == null)
          ActiveSessionEntity(
            id: laptopSessionId,
            deviceName: 'MacBook Air',
            deviceType: SessionDeviceType.computer,
            city: 'Алматы',
            lastActiveAt: DateTime(now.year, now.month, now.day - 5, 21, 14),
            isCurrent: false,
          ),
      ]),
      recentEvents: List<SecurityEventEntity>.unmodifiable(
        <SecurityEventEntity>[
          if (terminatedAt != null)
            SecurityEventEntity(
              id: 'event-sessions-terminated',
              kind: SecurityEventKind.otherSessionsTerminated,
              occurredAt: terminatedAt,
              deviceName: 'iPhone',
            ),
          SecurityEventEntity(
            id: 'event-signed-in',
            kind: SecurityEventKind.signedIn,
            occurredAt: signedInAt,
            deviceName: 'iPhone',
          ),
          SecurityEventEntity(
            id: 'event-app-code-changed',
            kind: SecurityEventKind.appCodeChanged,
            occurredAt: appCodeChangedAt,
          ),
        ],
      ),
      receivedAt: now,
    );
  }

  BillingOverviewEntity _billingOverview() {
    final DateTime now = _now();
    final _PlanTerms terms = _planTerms[_plan]!;
    final bool isPaid = terms.monthlyPrice > 0;
    // Charged on the 15th: the last charge is this month's after the 15th.
    const int chargeDay = 15;
    final DateTime lastChargeAt = now.day >= chargeDay
        ? DateTime(now.year, now.month, chargeDay)
        : DateTime(now.year, now.month - 1, chargeDay);
    final DateTime nextChargeAt = DateTime(
      lastChargeAt.year,
      lastChargeAt.month + 1,
      chargeDay,
    );
    final DateTime invoicePeriod = DateTime(
      lastChargeAt.year,
      lastChargeAt.month,
    );

    return BillingOverviewEntity(
      plan: _plan,
      isActive: true,
      monthlyPrice: terms.monthlyPrice,
      nextChargeAt: isPaid ? nextChargeAt : null,
      propertyUsage: PlanUsageEntity(
        used: _propertyCount,
        limit: terms.propertyLimit,
      ),
      memberUsage: PlanUsageEntity(
        used: _members.length,
        limit: terms.memberLimit,
      ),
      includedFeatures: terms.features,
      paymentCard: const PaymentCardEntity(
        brand: PaymentCardBrand.visa,
        lastDigits: '4218',
      ),
      latestInvoice: InvoiceEntity(
        id: 'invoice-${invoicePeriod.year}-${invoicePeriod.month}',
        period: invoicePeriod,
        amount: _planTerms[SubscriptionPlan.pro]!.monthlyPrice,
      ),
    );
  }

  static TeamMemberEntity _withName(
    TeamMemberEntity member, {
    required String firstName,
    required String lastName,
  }) {
    return TeamMemberEntity(
      id: member.id,
      firstName: firstName,
      lastName: lastName,
      phone: member.phone,
      role: member.role,
      propertyCount: member.propertyCount,
      hasAllProperties: member.hasAllProperties,
      isCurrentUser: member.isCurrentUser,
      status: member.status,
      inviteExpiresAt: member.inviteExpiresAt,
    );
  }
}

/// Price and limits of a subscription plan.
final class _PlanTerms {
  const _PlanTerms({
    required this.monthlyPrice,
    required this.propertyLimit,
    required this.memberLimit,
    required this.features,
  });

  /// In tenge.
  final int monthlyPrice;
  final int propertyLimit;
  final int memberLimit;
  final List<String> features;
}
