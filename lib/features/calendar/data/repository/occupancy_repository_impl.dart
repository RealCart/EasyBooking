import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_row_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_schedule_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/occupancy_week_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/occupancy_repository.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/repository/properties_repository.dart';

/// Reads the week's blocks from [CalendarSyncMockLocal] and lays them out
/// in one row per property. Names, prices, and favorites belong to the
/// properties feature, so the rows come from [PropertiesRepository] through
/// its domain contract; a property free all week still gets a row.
final class OccupancyRepositoryImpl implements OccupancyRepository {
  const OccupancyRepositoryImpl({
    required this._local,
    required this._properties,
  });

  final CalendarSyncMockLocal _local;
  final PropertiesRepository _properties;

  @override
  Future<Either<Failure, OccupancyWeekEntity>> getWeek({
    required bool favoritesOnly,
    DateTime? date,
  }) async {
    final Either<Failure, OccupancyScheduleEntity> result = await _local
        .loadSchedule(date);
    return result.flatMapAsync((OccupancyScheduleEntity schedule) async {
      final Either<Failure, List<PropertyEntity>> properties = await _properties
          .getProperties();
      return properties.map(
        (List<PropertyEntity> properties) => OccupancyWeekEntity(
          weekStart: schedule.weekStart,
          today: schedule.today,
          rows: List<OccupancyRowEntity>.unmodifiable(<OccupancyRowEntity>[
            for (final PropertyEntity property in properties)
              if (!favoritesOnly || property.isFavorite)
                _row(property, schedule.blocks),
          ]),
          syncCheckedAt: schedule.syncCheckedAt,
          isSyncHealthy: schedule.isSyncHealthy,
        ),
      );
    });
  }

  static OccupancyRowEntity _row(
    PropertyEntity property,
    List<OccupancyBlockEntity> blocks,
  ) {
    return OccupancyRowEntity(
      propertyId: property.id,
      propertyName: property.name,
      unit: property.unit,
      pricePerNight: property.pricePerNight,
      blocks: List<OccupancyBlockEntity>.unmodifiable(
        blocks.where(
          (OccupancyBlockEntity block) => block.propertyId == property.id,
        ),
      ),
    );
  }
}
