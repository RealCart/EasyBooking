import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_day_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/calendar_event_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/calendar_repository.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

/// Reads the day from [CalendarMockLocal]. Favorites belong to the
/// properties feature, so [getDay] asks [PropertiesRepository] for them
/// through its domain contract, and stays in sync with the hearts there.
final class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl({
    required this._local,
    required this._properties,
  });

  final CalendarMockLocal _local;
  final PropertiesRepository _properties;

  @override
  Future<Either<Failure, CalendarDayEntity>> getDay({
    required bool favoritesOnly,
    DateTime? date,
  }) async {
    final Either<Failure, CalendarDayEntity> result = await _local.loadDay(
      date,
    );
    if (!favoritesOnly) {
      return result;
    }
    return result.flatMapAsync((CalendarDayEntity day) async {
      final Either<Failure, List<PropertyEntity>> properties = await _properties
          .getProperties();
      return properties.map((List<PropertyEntity> properties) {
        final Set<String> favoriteIds = <String>{
          for (final PropertyEntity property in properties)
            if (property.isFavorite) property.id,
        };
        return day.withEvents(
          List<CalendarEventEntity>.unmodifiable(
            day.events.where(
              (CalendarEventEntity event) =>
                  favoriteIds.contains(event.propertyId),
            ),
          ),
        );
      });
    });
  }
}
