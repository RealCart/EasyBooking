import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/update_notification_settings_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_notification_settings_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_notification_settings_usecase.dart';

part 'notification_settings_event.dart';
part 'notification_settings_state.dart';

/// «Настройки уведомлений»: loads the saved settings and saves the edited
/// ones. The screen keeps the unsaved toggles itself.
final class NotificationSettingsBloc
    extends Bloc<NotificationSettingsEvent, NotificationSettingsState> {
  NotificationSettingsBloc({
    required this._getNotificationSettings,
    required this._updateNotificationSettings,
  }) : super(const NotificationSettingsState()) {
    on<NotificationSettingsRequested>(_onRequested, transformer: restartable());
    on<NotificationSettingsSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetNotificationSettingsUsecase _getNotificationSettings;
  final UpdateNotificationSettingsUsecase _updateNotificationSettings;

  /// Bumped by every successful save, so a load that started earlier does
  /// not replace the saved settings with older ones.
  int _saveCount = 0;

  Future<void> _onRequested(
    NotificationSettingsRequested event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    final int saveCount = _saveCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, NotificationSettingsEntity> result =
        await _getNotificationSettings(const NoParams());
    if (emit.isDone) {
      return;
    }
    if (saveCount != _saveCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, NotificationSettingsEntity>(
        value: final Failure failure,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, NotificationSettingsEntity>(
        value: final NotificationSettingsEntity settings,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            settings: settings,
          ),
        );
    }
  }

  Future<void> _onSubmitted(
    NotificationSettingsSubmitted event,
    Emitter<NotificationSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        resetSaveFailure: true,
      ),
    );

    final Either<Failure, NotificationSettingsEntity> result =
        await _updateNotificationSettings(event.params);
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, NotificationSettingsEntity>(
        value: final Failure failure,
      ):
        emit(
          state.copyWith(
            saveStatus: RequestStatus.failure,
            saveFailure: failure,
          ),
        );
      case Right<Failure, NotificationSettingsEntity>(
        value: final NotificationSettingsEntity settings,
      ):
        _saveCount += 1;
        emit(
          state.copyWith(saveStatus: RequestStatus.success, settings: settings),
        );
    }
  }
}
