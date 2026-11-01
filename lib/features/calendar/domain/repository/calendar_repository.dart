import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';

abstract interface class CalendarRepository {
  /// The events of [date] (`null` for today). With [favoritesOnly], only
  /// those of favorite properties. Served by a mock source until the
  /// calendar API exists.
  Future<Either<Failure, CalendarDayEntity>> getDay({
    required bool favoritesOnly,
    DateTime? date,
  });
}
