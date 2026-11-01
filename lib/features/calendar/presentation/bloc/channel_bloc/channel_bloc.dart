import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/disconnect_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/get_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/sync_channel_params_entity.dart';
import 'package:easy_booking/features/calendar/domain/usecases/disconnect_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/get_channel_usecase.dart';
import 'package:easy_booking/features/calendar/domain/usecases/sync_channel_usecase.dart';

part 'channel_event.dart';
part 'channel_state.dart';

/// One channel on «Канал»: its calendars, «Синхронизировать сейчас», and
/// «Отключить».
final class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  ChannelBloc({
    required this._getChannel,
    required this._syncChannel,
    required this._disconnectChannel,
  }) : super(const ChannelState()) {
    on<ChannelRequested>(_onRequested, transformer: restartable());
    on<ChannelSyncRequested>(_onSyncRequested, transformer: droppable());
    on<ChannelDisconnectRequested>(
      _onDisconnectRequested,
      transformer: droppable(),
    );
  }

  final GetChannelUsecase _getChannel;
  final SyncChannelUsecase _syncChannel;
  final DisconnectChannelUsecase _disconnectChannel;

  Future<void> _onRequested(
    ChannelRequested event,
    Emitter<ChannelState> emit,
  ) async {
    emit(
      state.copyWith(
        channelId: event.channelId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, ChannelEntity> result = await _getChannel(
      GetChannelParamsEntity(channelId: event.channelId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ChannelEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, ChannelEntity>(value: final ChannelEntity channel):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, channel: channel),
        );
    }
  }

  /// Replaces the channel with the one the source returns after the import.
  Future<void> _onSyncRequested(
    ChannelSyncRequested event,
    Emitter<ChannelState> emit,
  ) async {
    final ChannelEntity? channel = state.channel;
    if (channel == null || state.isBusy) {
      return;
    }
    emit(
      state.copyWith(
        syncStatus: RequestStatus.loading,
        resetSyncFailure: true,
      ),
    );

    final Either<Failure, ChannelEntity> result = await _syncChannel(
      SyncChannelParamsEntity(channelId: channel.id),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ChannelEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            syncStatus: RequestStatus.failure,
            syncFailure: failure,
          ),
        );
      case Right<Failure, ChannelEntity>(value: final ChannelEntity synced):
        emit(
          state.copyWith(syncStatus: RequestStatus.success, channel: synced),
        );
    }
  }

  /// On success the screen leaves; the channel is not reloaded.
  Future<void> _onDisconnectRequested(
    ChannelDisconnectRequested event,
    Emitter<ChannelState> emit,
  ) async {
    final ChannelEntity? channel = state.channel;
    if (channel == null || state.isBusy) {
      return;
    }
    emit(
      state.copyWith(
        disconnectStatus: RequestStatus.loading,
        resetDisconnectFailure: true,
      ),
    );

    final Either<Failure, void> result = await _disconnectChannel(
      DisconnectChannelParamsEntity(channelId: channel.id),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(
          state.copyWith(
            disconnectStatus: RequestStatus.failure,
            disconnectFailure: failure,
          ),
        );
      case Right<Failure, void>():
        emit(state.copyWith(disconnectStatus: RequestStatus.success));
    }
  }
}
