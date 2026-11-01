import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/sync_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

final class SyncChannelUsecase
    implements
        Usecase<
          Future<Either<Failure, ChannelEntity>>,
          SyncChannelParamsEntity
        > {
  const SyncChannelUsecase(this._repository);

  final ChannelsRepository _repository;

  @override
  Future<Either<Failure, ChannelEntity>> call(SyncChannelParamsEntity params) {
    return _repository.syncChannel(params.channelId);
  }
}
