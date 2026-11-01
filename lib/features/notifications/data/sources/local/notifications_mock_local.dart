import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_entity.dart';
import 'package:easy_booking/features/notifications/domain/entity/notification_feed_entity.dart';

/// Sample notifications until the notifications API exists. Targets are
/// ids of the calendar sync, properties, contracts, and bookings mocks.
///
/// It returns entities directly: the API's response shape is not known yet,
/// so there are no models to map. Read state lives in memory, so it lasts
/// until the app restarts. Replace it with a `NotificationsRemote` returning
/// models when the endpoints are ready.
abstract interface class NotificationsMockLocal {
  Future<Either<Failure, NotificationFeedEntity>> loadFeed();

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();
}

final class NotificationsMockLocalImpl implements NotificationsMockLocal {
  /// [now] supplies the current time, so the sample feed is always recent.
  NotificationsMockLocalImpl({required this._now});

  static const String _conflictId = 'n-conflict';
  static const String _syncFailedId = 'n-sync-failed';
  static const String _contractUnsignedId = 'n-contract-unsigned';
  static const String _arrivalId = 'n-arrival';
  static const String _publishedId = 'n-published';
  static const String _contractSignedId = 'n-contract-signed';

  final DateTime Function() _now;

  /// Only the failed sync starts unread, as in the design.
  final Set<String> _readIds = <String>{
    _conflictId,
    _contractUnsignedId,
    _arrivalId,
    _publishedId,
    _contractSignedId,
  };

  @override
  Future<Either<Failure, NotificationFeedEntity>> loadFeed() async {
    final DateTime now = _now();

    DateTime yesterdayAt(int hour, int minute) {
      return DateTime(now.year, now.month, now.day - 1, hour, minute);
    }

    final String conflictDays = DateFormatter.dayRange(
      DateTime(now.year, now.month, now.day + 2),
      DateTime(now.year, now.month, now.day + 3),
    );

    return Right<Failure, NotificationFeedEntity>(
      NotificationFeedEntity(
        receivedAt: now,
        notifications: List<NotificationEntity>.unmodifiable(
          <NotificationEntity>[
            NotificationEntity(
              id: _conflictId,
              kind: NotificationKind.bookingConflict,
              title: 'Конфликт бронирований',
              body:
                  'Esentai City · $conflictDays пересекаются в Airbnb и '
                  'ручной брони.',
              createdAt: now.subtract(const Duration(minutes: 2)),
              targetId: 'conflict-esentai-84',
              isRead: _readIds.contains(_conflictId),
            ),
            NotificationEntity(
              id: _syncFailedId,
              kind: NotificationKind.syncFailed,
              title: 'Airbnb не обновился',
              body: 'Проверьте iCal-ссылку объекта Esentai City.',
              createdAt: now.subtract(const Duration(minutes: 21)),
              targetId: 'esentai-city-84',
              isRead: _readIds.contains(_syncFailedId),
            ),
            NotificationEntity(
              id: _contractUnsignedId,
              kind: NotificationKind.contractUnsigned,
              title: 'Договор ещё не подписан',
              body:
                  'Данияр открыл договор № EB-1052. Можно отправить '
                  'напоминание.',
              createdAt: now.subtract(const Duration(hours: 1)),
              targetId: 'eb-1052',
              isRead: _readIds.contains(_contractUnsignedId),
            ),
            NotificationEntity(
              id: _arrivalId,
              kind: NotificationKind.arrivalSoon,
              title: 'Заезд через 2 часа',
              body:
                  'Айжан · Esentai City · квартира 84. Код домофона '
                  'отправлен.',
              createdAt: now.subtract(const Duration(hours: 3)),
              targetId: 'booking-1042',
              isRead: _readIds.contains(_arrivalId),
            ),
            NotificationEntity(
              id: _publishedId,
              kind: NotificationKind.propertyPublished,
              title: 'Объект опубликован',
              body: 'Highvill · 5 готова к бронированиям.',
              createdAt: yesterdayAt(18, 42),
              // A property of the properties mock, so the notification
              // opens it; a published draft's id exists only in memory.
              targetId: 'highvill-5',
              isRead: _readIds.contains(_publishedId),
            ),
            NotificationEntity(
              id: _contractSignedId,
              kind: NotificationKind.contractSigned,
              title: 'Договор подписан',
              body: 'Асель подписала договор № EB-1049.',
              createdAt: yesterdayAt(12, 10),
              targetId: 'eb-1049',
              isRead: _readIds.contains(_contractSignedId),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    if (!_allIds.contains(id)) {
      return Left<Failure, void>(
        ServerFailure(statusCode: 404, message: 'Unknown notification $id'),
      );
    }
    _readIds.add(id);
    return const Right<Failure, void>(null);
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    _readIds.addAll(_allIds);
    return const Right<Failure, void>(null);
  }

  static const Set<String> _allIds = <String>{
    _conflictId,
    _syncFailedId,
    _contractUnsignedId,
    _arrivalId,
    _publishedId,
    _contractSignedId,
  };
}
