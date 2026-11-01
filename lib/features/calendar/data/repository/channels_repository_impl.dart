import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/data/sources/local/calendar_sync_mock_local.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

/// Reads from [CalendarSyncMockLocal], which already returns entities. The
/// mock has no single-channel read, so [getChannel] picks it from the
/// overview.
final class ChannelsRepositoryImpl implements ChannelsRepository {
  const ChannelsRepositoryImpl({required this._local});

  final CalendarSyncMockLocal _local;

  @override
  Future<Either<Failure, ChannelsOverviewEntity>> getChannels() {
    return _local.loadChannels();
  }

  @override
  Future<Either<Failure, ChannelEntity>> getChannel(String id) async {
    final Either<Failure, ChannelsOverviewEntity> result = await _local
        .loadChannels();
    return result.flatMap((ChannelsOverviewEntity overview) {
      for (final ChannelEntity channel in overview.channels) {
        if (channel.id == id) {
          return Right<Failure, ChannelEntity>(channel);
        }
      }
      return Left<Failure, ChannelEntity>(
        ServerFailure(statusCode: 404, message: 'Unknown channel $id'),
      );
    });
  }

  @override
  Future<Either<Failure, ChannelEntity>> syncChannel(String id) {
    return _local.syncChannel(id);
  }

  @override
  Future<Either<Failure, void>> disconnectChannel(String id) {
    return _local.disconnectChannel(id);
  }
}
