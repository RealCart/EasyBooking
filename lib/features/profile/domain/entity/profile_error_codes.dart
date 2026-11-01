/// Error codes of the profile feature, used in `ValidationFailure.code` and
/// as `ValidationFailure.fieldErrors` values.
///
/// Generic field codes (`required`, `invalid_email`, `invalid_phone`) are
/// shared with other features and come from `FieldErrorCodes`.
abstract final class ProfileErrorCodes {
  // Team.
  static const String alreadyInTeam = 'already_in_team';
  static const String ownerRoleNotAssignable = 'owner_role_not_assignable';
  static const String cannotRemoveOwner = 'cannot_remove_owner';
  static const String teamLimitReached = 'team_limit_reached';

  // Billing.
  static const String planLimitExceeded = 'plan_limit_exceeded';

  // Notification settings.
  static const String noDeliveryChannel = 'no_delivery_channel';
}
