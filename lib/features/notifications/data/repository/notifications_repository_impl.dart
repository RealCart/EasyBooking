import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/data/sources/local/notifications_mock_local.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';
import 'package:easy_booking/features/notifications/domain/repository/notifications_repository.dart';

/// Delegates to [NotificationsMockLocal], which already returns entities.
final class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl({required this._local});

  final NotificationsMockLocal _local;

  @override
  Future<Either<Failure, NotificationFeedEntity>> getFeed() {
    return _local.loadFeed();
  }

  @override
  Future<Either<Failure, void>> markRead(String id) => _local.markRead(id);

  @override
  Future<Either<Failure, void>> markAllRead() => _local.markAllRead();
}
