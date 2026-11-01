import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';

/// Served by a mock source until the calendar API exists.
abstract interface class OccupancyRepository {
  /// The week containing [date] (`null` for the current week), with a row
  /// per property. With [favoritesOnly], only rows of favorite properties.
  Future<Either<Failure, OccupancyWeekEntity>> getWeek({
    required bool favoritesOnly,
    DateTime? date,
  });
}
