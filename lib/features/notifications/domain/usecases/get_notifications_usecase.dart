import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';

final class GetNotificationsUsecase
    implements
        Usecase<Future<Either<Failure, NotificationFeedEntity>>, NoParams> {
  const GetNotificationsUsecase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, NotificationFeedEntity>> call(NoParams params) {
    return _repository.getFeed();
  }
}
