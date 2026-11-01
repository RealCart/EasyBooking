import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';

final class MarkAllNotificationsReadUsecase
    implements Usecase<Future<Either<Failure, void>>, NoParams> {
  const MarkAllNotificationsReadUsecase(this._repository);

  final NotificationsRepository _repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.markAllRead();
  }
}
