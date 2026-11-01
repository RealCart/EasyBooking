import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';

/// Served by a mock source until the notifications API exists.
abstract interface class NotificationsRepository {
  Future<Either<Failure, NotificationFeedEntity>> getFeed();

  /// Marks the notification [id] read; an unknown id is a failure.
  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();
}
