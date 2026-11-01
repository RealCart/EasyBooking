import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/repository/profile_repository.dart';

final class GetNotificationSettingsUsecase
    implements
        Usecase<Future<Either<Failure, NotificationSettingsEntity>>, NoParams> {
  const GetNotificationSettingsUsecase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Either<Failure, NotificationSettingsEntity>> call(NoParams params) {
    return _repository.getNotificationSettings();
  }
}
