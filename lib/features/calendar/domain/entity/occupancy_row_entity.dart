import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/calendar/domain/entity/occupancy_block_entity.dart';

/// One property's line on «Занятость».
final class OccupancyRowEntity extends Equatable {
  const OccupancyRowEntity({
    required this.propertyId,
    required this.propertyName,
    required this.unit,
    required this.pricePerNight,
    required this.blocks,
  });

  final String propertyId;

  /// Building or complex, such as `Esentai City`.
  final String propertyName;

  /// Apartment number within [propertyName].
  final String unit;

  /// Base price in whole tenge.
  final int pricePerNight;

  /// Blocks overlapping the week, ordered by start; empty when the property
  /// is free all week. They may start before or end after the week.
  final List<OccupancyBlockEntity> blocks;

  @override
  List<Object?> get props => <Object?>[
    propertyId,
    propertyName,
    unit,
    pricePerNight,
    blocks,
  ];
}
