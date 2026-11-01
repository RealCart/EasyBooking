import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

/// Saves «Настройки уведомлений». At least one delivery channel is required
/// (`ProfileErrorCodes.noDeliveryChannel`), otherwise nothing could be
/// delivered.
final class UpdateNotificationSettingsUsecase
    implements
        Usecase<
          Future<Either<Failure, NotificationSettingsEntity>>,
          UpdateNotificationSettingsParamsEntity
        > {
  const UpdateNotificationSettingsUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, NotificationSettingsEntity>> call(
    UpdateNotificationSettingsParamsEntity params,
  ) async {
    if (params.channels.isEmpty) {
      return const Left<Failure, NotificationSettingsEntity>(
        ValidationFailure(code: ProfileErrorCodes.noDeliveryChannel),
      );
    }
    return _repository.updateNotificationSettings(params);
  }
}
