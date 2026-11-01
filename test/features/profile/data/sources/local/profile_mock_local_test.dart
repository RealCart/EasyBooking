import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/data/sources/local/profile_mock_local.dart';
import 'package:easy_booking/features/profile/domain/entity/active_session_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/security_event_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';

import '../../../../../helpers/fake_profile_repository.dart';

T _right<T>(Either<Failure, T> result) {
  return result.fold(
    (Failure failure) => fail('Unexpected failure $failure'),
    (T value) => value,
  );
}

Failure _left<T>(Either<Failure, T> result) {
  return result.fold(
    (Failure failure) => failure,
    (T value) => fail('Unexpected success $value'),
  );
}

InviteTeamMemberParamsEntity _invite(
  String phone, {
  ProfileRole role = ProfileRole.checkInOperator,
}) {
  return InviteTeamMemberParamsEntity(
    firstName: 'Дана',
    lastName: 'Ахметова',
    phone: phone,
    role: role,
  );
}

void main() {
  late ProfileMockLocalImpl local;

  setUp(() {
    local = ProfileMockLocalImpl(now: () => profileTestNow);
  });

  group('ProfileMockLocalImpl profile', () {
    test(
      'an edit changes the details, the profile, and the owner row',
      () async {
        const UpdateProfileParamsEntity params = UpdateProfileParamsEntity(
          firstName: 'Алихан',
          lastName: 'Сейткали',
          email: 'a.seitkali@mail.kz',
          teamName: 'Алихан Апартаменты',
          city: KazakhstanCities.astana,
        );

        final ProfileDetailsEntity saved = _right(
          await local.updateProfile(params),
        );

        expect(
          saved,
          const ProfileDetailsEntity(
            firstName: 'Алихан',
            lastName: 'Сейткали',
            phone: '+77012345678',
            email: 'a.seitkali@mail.kz',
            teamName: 'Алихан Апартаменты',
            city: KazakhstanCities.astana,
          ),
        );
        expect(_right(await local.loadProfileDetails()), saved);
        final ProfileEntity profile = _right(await local.loadProfile());
        expect(profile.fullName, 'Алихан Сейткали');
        expect(profile.city, 'Астана');
        final List<TeamMemberEntity> team = _right(await local.loadTeam());
        final TeamMemberEntity owner = team.firstWhere(
          (TeamMemberEntity member) => member.isCurrentUser,
        );
        expect(owner.fullName, 'Алихан Сейткали');
        expect(owner.id, ProfileMockLocalImpl.ownerId);
        expect(owner.role, ProfileRole.owner);
        expect(team[1].fullName, 'Алия Жумабек');
      },
    );
  });

  group('ProfileMockLocalImpl team', () {
    test('starts with the owner first and two members', () async {
      final List<TeamMemberEntity> team = _right(await local.loadTeam());

      expect(team.map((TeamMemberEntity member) => member.id), <String>[
        ProfileMockLocalImpl.ownerId,
        ProfileMockLocalImpl.managerId,
        ProfileMockLocalImpl.cleanerId,
      ]);
      expect(team.first.isCurrentUser, isTrue);
    });

    test(
      'a valid invite adds an invited member that expires in 72 hours',
      () async {
        final List<TeamMemberEntity> team = _right(
          await local.inviteTeamMember(_invite('+77005551234')),
        );

        expect(team, hasLength(4));
        final TeamMemberEntity invited = team.last;
        expect(invited.fullName, 'Дана Ахметова');
        expect(invited.phone, '+77005551234');
        expect(invited.role, ProfileRole.checkInOperator);
        expect(invited.status, TeamMemberStatus.invited);
        expect(invited.isCurrentUser, isFalse);
        expect(invited.propertyCount, 0);
        expect(invited.inviteExpiresAt, DateTime(2026, 10, 25, 14));
        expect(_right(await local.loadTeam()), team);
        expect(_right(await local.loadProfile()).teamMemberCount, 3);
        expect(() => team.add(invited), throwsUnsupportedError);
      },
    );

    test('a phone already in the team fails on the phone field', () async {
      final Failure failure = _left(
        await local.inviteTeamMember(_invite('+77015550142')),
      );

      expect(
        failure,
        const ValidationFailure(
          fieldErrors: <String, String>{
            ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
          },
        ),
      );
      expect(_right(await local.loadTeam()), hasLength(3));
    });

    test('an owner role is refused', () async {
      expect(
        _left(
          await local.inviteTeamMember(
            _invite('+77005551234', role: ProfileRole.owner),
          ),
        ),
        const ValidationFailure(code: ProfileErrorCodes.ownerRoleNotAssignable),
      );
    });

    test('a sixth member on Pro fails with teamLimitReached', () async {
      _right(await local.inviteTeamMember(_invite('+77005550001')));
      _right(await local.inviteTeamMember(_invite('+77005550002')));

      final Failure failure = _left(
        await local.inviteTeamMember(_invite('+77005550003')),
      );

      expect(
        failure,
        const ValidationFailure(code: ProfileErrorCodes.teamLimitReached),
      );
      expect(_right(await local.loadTeam()), hasLength(5));
    });

    test('invited members get distinct ids', () async {
      _right(await local.inviteTeamMember(_invite('+77005550001')));
      final List<TeamMemberEntity> team = _right(
        await local.inviteTeamMember(_invite('+77005550002')),
      );

      expect(team[3].id, isNot(team[4].id));
    });

    test('removing a member drops them from later reads', () async {
      final List<TeamMemberEntity> team = _right(
        await local.removeTeamMember(ProfileMockLocalImpl.managerId),
      );

      expect(team.map((TeamMemberEntity member) => member.id), <String>[
        ProfileMockLocalImpl.ownerId,
        ProfileMockLocalImpl.cleanerId,
      ]);
      expect(_right(await local.loadTeam()), team);
      expect(_right(await local.loadProfile()).teamMemberCount, 1);
    });

    test('removing an unknown id fails with a 404', () async {
      final Failure failure = _left(await local.removeTeamMember('nobody'));

      expect(failure, isA<ServerFailure>());
      expect((failure as ServerFailure).statusCode, 404);
      expect(_right(await local.loadTeam()), hasLength(3));
    });

    test('removing the owner fails with cannotRemoveOwner', () async {
      expect(
        _left(await local.removeTeamMember(ProfileMockLocalImpl.ownerId)),
        const ValidationFailure(code: ProfileErrorCodes.cannotRemoveOwner),
      );
      expect(_right(await local.loadTeam()), hasLength(3));
    });
  });

  group('ProfileMockLocalImpl notification settings', () {
    test('a save replaces the settings for later reads', () async {
      const UpdateNotificationSettingsParamsEntity params =
          UpdateNotificationSettingsParamsEntity(
            enabledTopics: <NotificationTopic>{NotificationTopic.priceChange},
            channels: <NotificationDeliveryChannel>{
              NotificationDeliveryChannel.email,
              NotificationDeliveryChannel.sms,
            },
          );

      final NotificationSettingsEntity saved = _right(
        await local.updateNotificationSettings(params),
      );

      expect(saved.enabledTopics, <NotificationTopic>{
        NotificationTopic.priceChange,
      });
      expect(saved.channels, params.channels);
      expect(_right(await local.loadNotificationSettings()), saved);
    });

    test('an empty channel set fails and keeps the old settings', () async {
      final NotificationSettingsEntity before = _right(
        await local.loadNotificationSettings(),
      );

      expect(
        _left(
          await local.updateNotificationSettings(
            const UpdateNotificationSettingsParamsEntity(
              enabledTopics: <NotificationTopic>{},
              channels: <NotificationDeliveryChannel>{},
            ),
          ),
        ),
        const ValidationFailure(code: ProfileErrorCodes.noDeliveryChannel),
      );
      expect(_right(await local.loadNotificationSettings()), before);
    });
  });

  group('ProfileMockLocalImpl security', () {
    test('starts with this iPhone and a MacBook', () async {
      final SecurityOverviewEntity overview = _right(
        await local.loadSecurityOverview(),
      );

      expect(
        overview.sessions.map((ActiveSessionEntity session) => session.id),
        <String>[
          ProfileMockLocalImpl.currentSessionId,
          ProfileMockLocalImpl.laptopSessionId,
        ],
      );
      expect(overview.sessions.first.lastActiveAt, profileTestNow);
      expect(overview.isBiometricLoginEnabled, isTrue);
    });

    test('the biometric switch persists', () async {
      final SecurityOverviewEntity overview = _right(
        await local.setBiometricLogin(isEnabled: false),
      );

      expect(overview.isBiometricLoginEnabled, isFalse);
      expect(
        _right(await local.loadSecurityOverview()).isBiometricLoginEnabled,
        isFalse,
      );
    });

    test(
      'terminating leaves only the current session and adds an event',
      () async {
        final SecurityOverviewEntity overview = _right(
          await local.terminateOtherSessions(),
        );

        expect(
          overview.sessions.map((ActiveSessionEntity session) => session.id),
          <String>[ProfileMockLocalImpl.currentSessionId],
        );
        expect(overview.otherSessions, isEmpty);
        final SecurityEventEntity event = overview.recentEvents.first;
        expect(event.kind, SecurityEventKind.otherSessionsTerminated);
        expect(event.occurredAt, profileTestNow);
        expect(_right(await local.loadSecurityOverview()), overview);
      },
    );
  });

  group('ProfileMockLocalImpl billing', () {
    test('starts on Pro with the team usage', () async {
      final BillingOverviewEntity overview = _right(
        await local.loadBillingOverview(),
      );

      expect(overview.plan, SubscriptionPlan.pro);
      expect(overview.monthlyPrice, 3990);
      expect(overview.memberUsage.used, 3);
      expect(overview.memberUsage.limit, 5);
      expect(overview.propertyUsage.used, 4);
      // 22 October is after the 15th: next charge on 15 November.
      expect(overview.nextChargeAt, DateTime(2026, 11, 15));
    });

    test(
      'Free with more than 2 members fails with planLimitExceeded',
      () async {
        expect(
          _left(await local.changePlan(SubscriptionPlan.free)),
          const ValidationFailure(code: ProfileErrorCodes.planLimitExceeded),
        );
        expect(
          _right(await local.loadBillingOverview()).plan,
          SubscriptionPlan.pro,
        );
        expect(_right(await local.loadProfile()).plan, SubscriptionPlan.pro);
      },
    );

    test(
      'a successful switch changes the overview and the profile plan',
      () async {
        _right(await local.removeTeamMember(ProfileMockLocalImpl.cleanerId));

        final BillingOverviewEntity overview = _right(
          await local.changePlan(SubscriptionPlan.free),
        );

        expect(overview.plan, SubscriptionPlan.free);
        expect(overview.monthlyPrice, 0);
        expect(overview.nextChargeAt, isNull);
        expect(overview.memberUsage.limit, 2);
        expect(_right(await local.loadBillingOverview()), overview);
        expect(_right(await local.loadProfile()).plan, SubscriptionPlan.free);
      },
    );
  });

  group('ProfileMockLocalImpl help', () {
    test('returns the support contact, topics, and guides', () async {
      final HelpCenterEntity result = _right(await local.loadHelpCenter());

      expect(result.support.isOnline, isTrue);
      expect(result.topics, isNotEmpty);
      expect(result.guides, isNotEmpty);
    });
  });
}
