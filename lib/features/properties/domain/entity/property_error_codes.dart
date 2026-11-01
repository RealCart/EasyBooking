import 'package:easy_booking/core/utils/error/field_error_codes.dart';

/// Error codes of the properties feature, used in `ValidationFailure.code`
/// and as `ValidationFailure.fieldErrors` values.
///
/// Codes shared with other features alias [FieldErrorCodes].
abstract final class PropertyErrorCodes {
  // Field codes.
  static const String required = FieldErrorCodes.required;

  /// A number or time outside the limits in [PropertyLimits].
  static const String outOfRange = 'out_of_range';

  // Request codes.

  /// Publishing before step 1 of the draft was saved.
  static const String draftIncomplete = 'draft_incomplete';
}

/// Limits the add-property use cases check.
abstract final class PropertyLimits {
  static const int minRooms = 1;
  static const int maxRooms = 20;
  static const int minNights = 1;
  static const int maxMinNights = 30;
}
