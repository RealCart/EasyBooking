import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/disconnect_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/repository/channels_repository.dart';

final class DisconnectChannelUsecase
    implements
        Usecase<Future<Either<Failure, void>>, DisconnectChannelParamsEntity> {
  const DisconnectChannelUsecase(this._repository);

  final ChannelsRepository _repository;

  @override
  Future<Either<Failure, void>> call(DisconnectChannelParamsEntity params) {
    return _repository.disconnectChannel(params.channelId);
  }
}
