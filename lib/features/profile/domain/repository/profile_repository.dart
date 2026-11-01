import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
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

/// The signed-in user's profile, team, settings, and subscription. Served by
/// a mock source until the profile API exists; every write changes what
/// later reads return.
abstract interface class ProfileRepository {
  /// The signed-in user's profile.
  Future<Either<Failure, ProfileEntity>> getProfile();

  Future<Either<Failure, ProfileDetailsEntity>> getProfileDetails();

  /// Saves already validated [params] and returns the saved details.
  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  );

  /// Team members, the current user first.
  Future<Either<Failure, List<TeamMemberEntity>>> getTeam();

  /// Invites a member with an E.164 phone and returns the updated team.
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  );

  /// Returns the updated team.
  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  );

  Future<Either<Failure, NotificationSettingsEntity>> getNotificationSettings();

  /// Returns the saved settings.
  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(UpdateNotificationSettingsParamsEntity params);

  Future<Either<Failure, SecurityOverviewEntity>> getSecurityOverview();

  /// Returns the updated overview.
  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  });

  /// Signs out every session except the current one and returns the updated
  /// overview.
  Future<Either<Failure, SecurityOverviewEntity>> terminateOtherSessions();

  Future<Either<Failure, BillingOverviewEntity>> getBillingOverview();

  /// Returns the updated overview.
  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  );

  Future<Either<Failure, HelpCenterEntity>> getHelpCenter();
}
