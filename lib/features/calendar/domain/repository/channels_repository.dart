import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';

/// Served by a mock source until the channels API exists.
abstract interface class ChannelsRepository {
  Future<Either<Failure, ChannelsOverviewEntity>> getChannels();

  /// The channel [id]; an unknown id is a failure.
  Future<Either<Failure, ChannelEntity>> getChannel(String id);

  /// Imports the channel's calendars now and returns the channel after the
  /// import. A disconnected channel cannot be synced.
  Future<Either<Failure, ChannelEntity>> syncChannel(String id);

  /// Stops importing and exporting the channel's calendars.
  Future<Either<Failure, void>> disconnectChannel(String id);
}
