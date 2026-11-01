import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/data/repository/profile_repository_impl.dart';
import 'package:easy_booking/features/profile/data/sources/local/profile_mock_local.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';

import '../../../helpers/fake_profile_repository.dart';

const Failure _failure = StorageFailure(message: 'disk');

const UpdateProfileParamsEntity _updateParams = UpdateProfileParamsEntity(
  firstName: 'Алихан',
  lastName: 'Сейткали',
  email: 'a@b.kz',
  teamName: 'Команда',
  city: KazakhstanCities.astana,
);

const InviteTeamMemberParamsEntity _inviteParams = InviteTeamMemberParamsEntity(
  firstName: 'Дана',
  lastName: 'Ахметова',
  phone: '+77005551234',
  role: ProfileRole.cleaner,
);

const UpdateNotificationSettingsParamsEntity _settingsParams =
    UpdateNotificationSettingsParamsEntity(
      enabledTopics: <NotificationTopic>{NotificationTopic.priceChange},
      channels: <NotificationDeliveryChannel>{NotificationDeliveryChannel.sms},
    );

/// [ProfileMockLocal] with settable results that records every call. Set
/// [error] to make every call throw it.
final class _FakeProfileMockLocal implements ProfileMockLocal {
  Either<Failure, ProfileEntity> profileResult =
      const Right<Failure, ProfileEntity>(testProfile);
  Either<Failure, ProfileDetailsEntity> detailsResult =
      const Right<Failure, ProfileDetailsEntity>(testProfileDetails);
  Either<Failure, List<TeamMemberEntity>> teamResult =
      const Right<Failure, List<TeamMemberEntity>>(testTeam);
  Either<Failure, NotificationSettingsEntity> settingsResult =
      const Right<Failure, NotificationSettingsEntity>(
        testNotificationSettings,
      );
  Either<Failure, SecurityOverviewEntity> securityResult =
      Right<Failure, SecurityOverviewEntity>(testSecurityOverview());
  Either<Failure, BillingOverviewEntity> billingResult =
      Right<Failure, BillingOverviewEntity>(testBillingOverview());
  Either<Failure, HelpCenterEntity> helpResult =
      const Right<Failure, HelpCenterEntity>(testHelpCenter);

  Object? error;

  /// Every call with its argument, such as `invite`, `params`.
  final List<(String, Object?)> calls = <(String, Object?)>[];

  Future<T> _record<T>(String name, Object? argument, T result) async {
    calls.add((name, argument));
    final Object? error = this.error;
    if (error != null) {
      throw error;
    }
    return result;
  }

  @override
  Future<Either<Failure, ProfileEntity>> loadProfile() {
    return _record('loadProfile', null, profileResult);
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> loadProfileDetails() {
    return _record('loadProfileDetails', null, detailsResult);
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  ) {
    return _record('updateProfile', params, detailsResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> loadTeam() {
    return _record('loadTeam', null, teamResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  ) {
    return _record('inviteTeamMember', params, teamResult);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  ) {
    return _record('removeTeamMember', memberId, teamResult);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  loadNotificationSettings() {
    return _record('loadNotificationSettings', null, settingsResult);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(UpdateNotificationSettingsParamsEntity params) {
    return _record('updateNotificationSettings', params, settingsResult);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> loadSecurityOverview() {
    return _record('loadSecurityOverview', null, securityResult);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  }) {
    return _record('setBiometricLogin', isEnabled, securityResult);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> terminateOtherSessions() {
    return _record('terminateOtherSessions', null, securityResult);
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> loadBillingOverview() {
    return _record('loadBillingOverview', null, billingResult);
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  ) {
    return _record('changePlan', plan, billingResult);
  }

  @override
  Future<Either<Failure, HelpCenterEntity>> loadHelpCenter() {
    return _record('loadHelpCenter', null, helpResult);
  }
}

void main() {
  group('ProfileMockLocalImpl', () {
    test('returns the profile of the design', () async {
      final Either<Failure, ProfileEntity> result = await ProfileMockLocalImpl(
        now: () => profileTestNow,
      ).loadProfile();
      final ProfileEntity profile = result.fold(
        (Failure failure) => fail('Unexpected failure $failure'),
        (ProfileEntity profile) => profile,
      );

      expect(profile.fullName, 'Бексултан Нишанбек');
      expect(profile.role, ProfileRole.owner);
      expect(profile.propertyCount, 4);
      expect(profile.teamMemberCount, 2);
      expect(profile.plan, SubscriptionPlan.pro);
    });
  });

  group('ProfileRepositoryImpl', () {
    late _FakeProfileMockLocal local;
    late ProfileRepositoryImpl repository;

    setUp(() {
      local = _FakeProfileMockLocal();
      repository = ProfileRepositoryImpl(local: local);
    });

    test('getProfile passes the source result through unchanged', () async {
      local.profileResult = const Left<Failure, ProfileEntity>(_failure);

      expect(
        await repository.getProfile(),
        const Left<Failure, ProfileEntity>(_failure),
      );
      expect(local.calls, <(String, Object?)>[('loadProfile', null)]);
    });

    test('reads return the source entities and failures unchanged', () async {
      expect(
        await repository.getProfileDetails(),
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      expect(
        await repository.getTeam(),
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      expect(
        await repository.getNotificationSettings(),
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      expect(
        await repository.getSecurityOverview(),
        Right<Failure, SecurityOverviewEntity>(testSecurityOverview()),
      );
      expect(
        await repository.getBillingOverview(),
        Right<Failure, BillingOverviewEntity>(testBillingOverview()),
      );
      expect(
        await repository.getHelpCenter(),
        const Right<Failure, HelpCenterEntity>(testHelpCenter),
      );

      local
        ..detailsResult = const Left<Failure, ProfileDetailsEntity>(_failure)
        ..teamResult = const Left<Failure, List<TeamMemberEntity>>(_failure)
        ..settingsResult = const Left<Failure, NotificationSettingsEntity>(
          _failure,
        )
        ..securityResult = const Left<Failure, SecurityOverviewEntity>(
          _failure,
        )
        ..billingResult = const Left<Failure, BillingOverviewEntity>(_failure)
        ..helpResult = const Left<Failure, HelpCenterEntity>(_failure);

      expect(
        await repository.getProfileDetails(),
        const Left<Failure, ProfileDetailsEntity>(_failure),
      );
      expect(
        await repository.getTeam(),
        const Left<Failure, List<TeamMemberEntity>>(_failure),
      );
      expect(
        await repository.getNotificationSettings(),
        const Left<Failure, NotificationSettingsEntity>(_failure),
      );
      expect(
        await repository.getSecurityOverview(),
        const Left<Failure, SecurityOverviewEntity>(_failure),
      );
      expect(
        await repository.getBillingOverview(),
        const Left<Failure, BillingOverviewEntity>(_failure),
      );
      expect(
        await repository.getHelpCenter(),
        const Left<Failure, HelpCenterEntity>(_failure),
      );
    });

    test('writes forward their arguments to the source', () async {
      await repository.updateProfile(_updateParams);
      await repository.inviteTeamMember(_inviteParams);
      await repository.removeTeamMember('member-aliya');
      await repository.updateNotificationSettings(_settingsParams);
      await repository.setBiometricLogin(isEnabled: false);
      await repository.terminateOtherSessions();
      await repository.changePlan(SubscriptionPlan.free);

      expect(local.calls, <(String, Object?)>[
        ('updateProfile', _updateParams),
        ('inviteTeamMember', _inviteParams),
        ('removeTeamMember', 'member-aliya'),
        ('updateNotificationSettings', _settingsParams),
        ('setBiometricLogin', false),
        ('terminateOtherSessions', null),
        ('changePlan', SubscriptionPlan.free),
      ]);
    });

    test('writes pass a typed failure through unchanged', () async {
      const Failure validation = ValidationFailure(code: 'team_limit_reached');
      local
        ..teamResult = const Left<Failure, List<TeamMemberEntity>>(validation)
        ..billingResult = const Left<Failure, BillingOverviewEntity>(
          validation,
        );

      expect(
        await repository.inviteTeamMember(_inviteParams),
        const Left<Failure, List<TeamMemberEntity>>(validation),
      );
      expect(
        await repository.changePlan(SubscriptionPlan.free),
        const Left<Failure, BillingOverviewEntity>(validation),
      );
    });

    test('an Error thrown by the source propagates', () async {
      local.error = StateError('defect');

      await expectLater(repository.getTeam(), throwsStateError);
      await expectLater(
        repository.updateProfile(_updateParams),
        throwsStateError,
      );
    });
  });
}
