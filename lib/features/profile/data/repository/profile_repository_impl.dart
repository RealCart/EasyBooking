import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
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
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Reads and writes through [ProfileMockLocal], which already returns
/// entities, so every call is passed through unchanged.
final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required this._local});

  final ProfileMockLocal _local;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() => _local.loadProfile();

  @override
  Future<Either<Failure, ProfileDetailsEntity>> getProfileDetails() {
    return _local.loadProfileDetails();
  }

  @override
  Future<Either<Failure, ProfileDetailsEntity>> updateProfile(
    UpdateProfileParamsEntity params,
  ) {
    return _local.updateProfile(params);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> getTeam() {
    return _local.loadTeam();
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> inviteTeamMember(
    InviteTeamMemberParamsEntity params,
  ) {
    return _local.inviteTeamMember(params);
  }

  @override
  Future<Either<Failure, List<TeamMemberEntity>>> removeTeamMember(
    String memberId,
  ) {
    return _local.removeTeamMember(memberId);
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  getNotificationSettings() {
    return _local.loadNotificationSettings();
  }

  @override
  Future<Either<Failure, NotificationSettingsEntity>>
  updateNotificationSettings(UpdateNotificationSettingsParamsEntity params) {
    return _local.updateNotificationSettings(params);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> getSecurityOverview() {
    return _local.loadSecurityOverview();
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> setBiometricLogin({
    required bool isEnabled,
  }) {
    return _local.setBiometricLogin(isEnabled: isEnabled);
  }

  @override
  Future<Either<Failure, SecurityOverviewEntity>> terminateOtherSessions() {
    return _local.terminateOtherSessions();
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> getBillingOverview() {
    return _local.loadBillingOverview();
  }

  @override
  Future<Either<Failure, BillingOverviewEntity>> changePlan(
    SubscriptionPlan plan,
  ) {
    return _local.changePlan(plan);
  }

  @override
  Future<Either<Failure, HelpCenterEntity>> getHelpCenter() {
    return _local.loadHelpCenter();
  }
}
