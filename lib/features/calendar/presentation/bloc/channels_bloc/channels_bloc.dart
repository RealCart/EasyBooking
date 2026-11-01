import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channels_usecase.dart';

part 'channels_event.dart';
part 'channels_state.dart';

/// The channel list of «Каналы».
final class ChannelsBloc extends Bloc<ChannelsEvent, ChannelsState> {
  ChannelsBloc({required this._getChannels}) : super(const ChannelsState()) {
    on<ChannelsRequested>(_onRequested, transformer: restartable());
  }

  final GetChannelsUsecase _getChannels;

  Future<void> _onRequested(
    ChannelsRequested event,
    Emitter<ChannelsState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, ChannelsOverviewEntity> result = await _getChannels(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ChannelsOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, ChannelsOverviewEntity>(
        value: final ChannelsOverviewEntity overview,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            overview: overview,
          ),
        );
    }
  }
}
