import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/error/field_error_message.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';

extension ProfileFailureMessage on Failure {
  /// Text for a profile failure. Known profile codes get their own message;
  /// anything else falls back to the shared [userMessage].
  String get profileMessage {
    final String? code = switch (this) {
      ValidationFailure(:final String? code) => code,
      ServerFailure(:final String? code) => code,
      _ => null,
    };
    return switch (code) {
      ProfileErrorCodes.teamLimitReached =>
        'В команде нет свободных мест. Смените тариф, чтобы пригласить ещё',
      ProfileErrorCodes.cannotRemoveOwner => 'Владельца нельзя удалить',
      ProfileErrorCodes.ownerRoleNotAssignable =>
        'Роль владельца нельзя назначить',
      ProfileErrorCodes.alreadyInTeam => _alreadyInTeamMessage,
      ProfileErrorCodes.planLimitExceeded =>
        'Объектов или участников больше, чем позволяет этот тариф',
      ProfileErrorCodes.noDeliveryChannel =>
        'Выберите хотя бы один канал доставки',
      _ => userMessage,
    };
  }
}

const String _alreadyInTeamMessage = 'Этот номер уже есть в команде';

/// Text for a profile or team form field error code, or `null` when the
/// field has no error.
String? profileFieldErrorMessage(String? code) {
  return switch (code) {
    ProfileErrorCodes.alreadyInTeam => _alreadyInTeamMessage,
    _ => fieldErrorMessage(code),
  };
}
