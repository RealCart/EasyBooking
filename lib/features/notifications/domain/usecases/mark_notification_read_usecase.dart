import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/notifications/domain/entity/mark_notification_read_params_entity.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';

final class MarkNotificationReadUsecase
    implements
        Usecase<
          Future<Either<Failure, void>>,
          MarkNotificationReadParamsEntity
        > {
  const MarkNotificationReadUsecase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, void>> call(MarkNotificationReadParamsEntity params) {
    return _repository.markRead(params.id);
  }
}
