import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/change_subscription_plan_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/invite_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/remove_team_member_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/set_biometric_login_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/team_member_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_team_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/invite_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/remove_team_member_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';

import '../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

UpdateProfileParamsEntity _profileParams({
  String firstName = '  Алихан ',
  String lastName = ' Сейткали ',
  String email = ' a.seitkali@mail.kz ',
  String teamName = ' Алихан Апартаменты ',
}) {
  return UpdateProfileParamsEntity(
    firstName: firstName,
    lastName: lastName,
    email: email,
    teamName: teamName,
    city: KazakhstanCities.astana,
  );
}

InviteTeamMemberParamsEntity _inviteParams({
  String firstName = ' Дана ',
  String lastName = ' Ахметова ',
  String phone = '700 555 12 34',
  ProfileRole role = ProfileRole.cleaner,
}) {
  return InviteTeamMemberParamsEntity(
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    role: role,
  );
}

void main() {
  late FakeProfileRepository repository;

  setUp(() {
    repository = FakeProfileRepository();
  });

  group('read use cases', () {
    test(
      'GetProfileDetailsUsecase returns the details or the failure',
      () async {
        final GetProfileDetailsUsecase usecase = GetProfileDetailsUsecase(
          repository,
        );

        expect(
          await usecase(const NoParams()),
          const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
        );
        repository.detailsResult = const Left<Failure, ProfileDetailsEntity>(
          _failure,
        );
        expect(
          await usecase(const NoParams()),
          const Left<Failure, ProfileDetailsEntity>(_failure),
        );
        expect(repository.detailsCount, 2);
      },
    );

    test('GetTeamUsecase returns the team or the failure', () async {
      final GetTeamUsecase usecase = GetTeamUsecase(repository);

      expect(
        await usecase(const NoParams()),
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      repository.teamResult = const Left<Failure, List<TeamMemberEntity>>(
        _failure,
      );
      expect(
        await usecase(const NoParams()),
        const Left<Failure, List<TeamMemberEntity>>(_failure),
      );
    });

    test(
      'GetNotificationSettingsUsecase returns the settings or the failure',
      () async {
        final GetNotificationSettingsUsecase usecase =
            GetNotificationSettingsUsecase(repository);

        expect(
          await usecase(const NoParams()),
          const Right<Failure, NotificationSettingsEntity>(
            testNotificationSettings,
          ),
        );
        repository.notificationSettingsResult =
            const Left<Failure, NotificationSettingsEntity>(_failure);
        expect(
          await usecase(const NoParams()),
          const Left<Failure, NotificationSettingsEntity>(_failure),
        );
      },
    );

    test(
      'GetSecurityOverviewUsecase returns the overview or the failure',
      () async {
        final GetSecurityOverviewUsecase usecase = GetSecurityOverviewUsecase(
          repository,
        );

        expect(
          await usecase(const NoParams()),
          Right<Failure, SecurityOverviewEntity>(testSecurityOverview()),
        );
        repository.securityResult = const Left<Failure, SecurityOverviewEntity>(
          _failure,
        );
        expect(
          await usecase(const NoParams()),
          const Left<Failure, SecurityOverviewEntity>(_failure),
        );
      },
    );

    test(
      'GetBillingOverviewUsecase returns the overview or the failure',
      () async {
        final GetBillingOverviewUsecase usecase = GetBillingOverviewUsecase(
          repository,
        );

        expect(
          await usecase(const NoParams()),
          Right<Failure, BillingOverviewEntity>(testBillingOverview()),
        );
        repository.billingResult = const Left<Failure, BillingOverviewEntity>(
          _failure,
        );
        expect(
          await usecase(const NoParams()),
          const Left<Failure, BillingOverviewEntity>(_failure),
        );
      },
    );

    test(
      'GetHelpCenterUsecase returns the help center or the failure',
      () async {
        final GetHelpCenterUsecase usecase = GetHelpCenterUsecase(repository);

        expect(
          await usecase(const NoParams()),
          const Right<Failure, HelpCenterEntity>(testHelpCenter),
        );
        repository.helpResult = const Left<Failure, HelpCenterEntity>(_failure);
        expect(
          await usecase(const NoParams()),
          const Left<Failure, HelpCenterEntity>(_failure),
        );
      },
    );
  });

  group('UpdateProfileUsecase', () {
    test('saves the trimmed form and returns the saved details', () async {
      final UpdateProfileUsecase usecase = UpdateProfileUsecase(repository);

      final Either<Failure, ProfileDetailsEntity> result = await usecase(
        _profileParams(),
      );

      expect(
        result,
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      expect(repository.updateProfileParams, const <UpdateProfileParamsEntity>[
        UpdateProfileParamsEntity(
          firstName: 'Алихан',
          lastName: 'Сейткали',
          email: 'a.seitkali@mail.kz',
          teamName: 'Алихан Апартаменты',
          city: KazakhstanCities.astana,
        ),
      ]);
    });

    test('blank fields fail as required without saving', () async {
      final UpdateProfileUsecase usecase = UpdateProfileUsecase(repository);

      final Either<Failure, ProfileDetailsEntity> result = await usecase(
        _profileParams(firstName: ' ', lastName: '', email: '  ', teamName: ''),
      );

      expect(
        result,
        const Left<Failure, ProfileDetailsEntity>(
          ValidationFailure(
            fieldErrors: <String, String>{
              ProfileFields.firstName: AuthErrorCodes.required,
              ProfileFields.lastName: AuthErrorCodes.required,
              ProfileFields.email: AuthErrorCodes.required,
              ProfileFields.teamName: AuthErrorCodes.required,
            },
          ),
        ),
      );
      expect(repository.updateProfileParams, isEmpty);
    });

    test('a malformed email fails as invalid_email without saving', () async {
      final UpdateProfileUsecase usecase = UpdateProfileUsecase(repository);

      final Either<Failure, ProfileDetailsEntity> result = await usecase(
        _profileParams(email: 'not-an-email'),
      );

      expect(
        result,
        const Left<Failure, ProfileDetailsEntity>(
          ValidationFailure(
            fieldErrors: <String, String>{
              ProfileFields.email: AuthErrorCodes.invalidEmail,
            },
          ),
        ),
      );
      expect(repository.updateProfileParams, isEmpty);
    });

    test('passes a repository failure through unchanged', () async {
      repository.updateProfileResult =
          const Left<Failure, ProfileDetailsEntity>(_failure);

      expect(
        await UpdateProfileUsecase(repository)(_profileParams()),
        const Left<Failure, ProfileDetailsEntity>(_failure),
      );
    });
  });

  group('InviteTeamMemberUsecase', () {
    test('sends a trimmed invitation with an E.164 phone', () async {
      final InviteTeamMemberUsecase usecase = InviteTeamMemberUsecase(
        repository,
      );

      final Either<Failure, List<TeamMemberEntity>> result = await usecase(
        _inviteParams(),
      );

      expect(result, const Right<Failure, List<TeamMemberEntity>>(testTeam));
      expect(
        repository.inviteParams,
        const <InviteTeamMemberParamsEntity>[
          InviteTeamMemberParamsEntity(
            firstName: 'Дана',
            lastName: 'Ахметова',
            phone: '+77005551234',
            role: ProfileRole.cleaner,
          ),
        ],
      );
    });

    test('an owner role is refused without sending', () async {
      final Either<Failure, List<TeamMemberEntity>> result =
          await InviteTeamMemberUsecase(repository)(
            _inviteParams(role: ProfileRole.owner),
          );

      expect(
        result,
        const Left<Failure, List<TeamMemberEntity>>(
          ValidationFailure(code: ProfileErrorCodes.ownerRoleNotAssignable),
        ),
      );
      expect(repository.inviteParams, isEmpty);
    });

    test(
      'blank names and a bad phone fail per field without sending',
      () async {
        final Either<Failure, List<TeamMemberEntity>> result =
            await InviteTeamMemberUsecase(repository)(
              _inviteParams(firstName: ' ', lastName: '', phone: '12345'),
            );

        expect(
          result,
          const Left<Failure, List<TeamMemberEntity>>(
            ValidationFailure(
              fieldErrors: <String, String>{
                ProfileFields.firstName: AuthErrorCodes.required,
                ProfileFields.lastName: AuthErrorCodes.required,
                ProfileFields.phone: AuthErrorCodes.invalidPhone,
              },
            ),
          ),
        );
        expect(repository.inviteParams, isEmpty);
      },
    );

    test('passes a repository failure through unchanged', () async {
      const Failure failure = ValidationFailure(
        fieldErrors: <String, String>{
          ProfileFields.phone: ProfileErrorCodes.alreadyInTeam,
        },
      );
      repository.inviteResult = const Left<Failure, List<TeamMemberEntity>>(
        failure,
      );

      expect(
        await InviteTeamMemberUsecase(repository)(_inviteParams()),
        const Left<Failure, List<TeamMemberEntity>>(failure),
      );
    });
  });

  group('RemoveTeamMemberUsecase', () {
    test('forwards the member id and returns the result', () async {
      final RemoveTeamMemberUsecase usecase = RemoveTeamMemberUsecase(
        repository,
      );

      expect(
        await usecase(
          const RemoveTeamMemberParamsEntity(memberId: 'member-aliya'),
        ),
        const Right<Failure, List<TeamMemberEntity>>(testTeam),
      );
      repository.removeResult = const Left<Failure, List<TeamMemberEntity>>(
        _failure,
      );
      expect(
        await usecase(
          const RemoveTeamMemberParamsEntity(memberId: 'member-aigerim'),
        ),
        const Left<Failure, List<TeamMemberEntity>>(_failure),
      );
      expect(repository.removedMemberIds, <String>[
        'member-aliya',
        'member-aigerim',
      ]);
    });
  });

  group('UpdateNotificationSettingsUsecase', () {
    const UpdateNotificationSettingsParamsEntity params =
        UpdateNotificationSettingsParamsEntity(
          enabledTopics: <NotificationTopic>{NotificationTopic.syncSuccess},
          channels: <NotificationDeliveryChannel>{
            NotificationDeliveryChannel.email,
          },
        );

    test('saves the settings and returns the saved ones', () async {
      final UpdateNotificationSettingsUsecase usecase =
          UpdateNotificationSettingsUsecase(repository);

      expect(
        await usecase(params),
        const Right<Failure, NotificationSettingsEntity>(
          testNotificationSettings,
        ),
      );
      expect(repository.updateNotificationSettingsParams, <Object>[params]);
    });

    test('no delivery channel fails without saving', () async {
      final Either<Failure, NotificationSettingsEntity> result =
          await UpdateNotificationSettingsUsecase(repository)(
            const UpdateNotificationSettingsParamsEntity(
              enabledTopics: <NotificationTopic>{NotificationTopic.newBooking},
              channels: <NotificationDeliveryChannel>{},
            ),
          );

      expect(
        result,
        const Left<Failure, NotificationSettingsEntity>(
          ValidationFailure(code: ProfileErrorCodes.noDeliveryChannel),
        ),
      );
      expect(repository.updateNotificationSettingsParams, isEmpty);
    });

    test('passes a repository failure through unchanged', () async {
      repository.updateNotificationSettingsResult =
          const Left<Failure, NotificationSettingsEntity>(_failure);

      expect(
        await UpdateNotificationSettingsUsecase(repository)(params),
        const Left<Failure, NotificationSettingsEntity>(_failure),
      );
    });
  });

  group('security use cases', () {
    test('SetBiometricLoginUsecase forwards the value', () async {
      final SetBiometricLoginUsecase usecase = SetBiometricLoginUsecase(
        repository,
      );

      expect(
        await usecase(const SetBiometricLoginParamsEntity(isEnabled: false)),
        Right<Failure, SecurityOverviewEntity>(testSecurityOverview()),
      );
      repository.biometricResult = const Left<Failure, SecurityOverviewEntity>(
        _failure,
      );
      expect(
        await usecase(const SetBiometricLoginParamsEntity(isEnabled: true)),
        const Left<Failure, SecurityOverviewEntity>(_failure),
      );
      expect(repository.biometricValues, <bool>[false, true]);
    });

    test(
      'TerminateOtherSessionsUsecase returns the overview or the failure',
      () async {
        final TerminateOtherSessionsUsecase usecase =
            TerminateOtherSessionsUsecase(repository);

        expect(
          await usecase(const NoParams()),
          Right<Failure, SecurityOverviewEntity>(
            testSecurityOverview(hasOtherSession: false),
          ),
        );
        repository.terminateResult =
            const Left<Failure, SecurityOverviewEntity>(_failure);
        expect(
          await usecase(const NoParams()),
          const Left<Failure, SecurityOverviewEntity>(_failure),
        );
        expect(repository.terminateCount, 2);
      },
    );
  });

  group('ChangeSubscriptionPlanUsecase', () {
    test('forwards the plan and returns the result', () async {
      final ChangeSubscriptionPlanUsecase usecase =
          ChangeSubscriptionPlanUsecase(repository);

      expect(
        await usecase(
          const ChangeSubscriptionPlanParamsEntity(plan: SubscriptionPlan.free),
        ),
        Right<Failure, BillingOverviewEntity>(testBillingOverview()),
      );
      const Failure limit = ValidationFailure(
        code: ProfileErrorCodes.planLimitExceeded,
      );
      repository.changePlanResult = const Left<Failure, BillingOverviewEntity>(
        limit,
      );
      expect(
        await usecase(
          const ChangeSubscriptionPlanParamsEntity(plan: SubscriptionPlan.pro),
        ),
        const Left<Failure, BillingOverviewEntity>(limit),
      );
      expect(repository.changedPlans, <SubscriptionPlan>[
        SubscriptionPlan.free,
        SubscriptionPlan.pro,
      ]);
    });
  });
}
