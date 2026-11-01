import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_settings_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/save_property_settings_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_settings_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_property_settings_usecase.dart';

part 'property_settings_event.dart';
part 'property_settings_state.dart';

/// The «Настройки» tab of one property.
final class PropertySettingsBloc
    extends Bloc<PropertySettingsEvent, PropertySettingsState> {
  PropertySettingsBloc({
    required this._getSettings,
    required this._saveSettings,
  }) : super(const PropertySettingsState()) {
    on<PropertySettingsRequested>(_onRequested, transformer: restartable());
    // A second tap on «Сохранить изменения» while saving is ignored.
    on<PropertySettingsSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetPropertySettingsUsecase _getSettings;
  final SavePropertySettingsUsecase _saveSettings;

  /// Keeps the shown settings while loading and after a failed refresh.
  Future<void> _onRequested(
    PropertySettingsRequested event,
    Emitter<PropertySettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        propertyId: event.propertyId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, PropertySettingsEntity> result = await _getSettings(
      GetPropertyParamsEntity(propertyId: event.propertyId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, PropertySettingsEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, PropertySettingsEntity>(
        value: final PropertySettingsEntity settings,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, settings: settings),
        );
    }
  }

  /// On success the stored settings replace the shown ones.
  Future<void> _onSubmitted(
    PropertySettingsSubmitted event,
    Emitter<PropertySettingsState> emit,
  ) async {
    emit(
      state.copyWith(saveStatus: RequestStatus.loading, resetSaveFailure: true),
    );

    final Either<Failure, PropertySettingsEntity> result = await _saveSettings(
      event.params,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, PropertySettingsEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            saveStatus: RequestStatus.failure,
            saveFailure: failure,
          ),
        );
      case Right<Failure, PropertySettingsEntity>(
        value: final PropertySettingsEntity settings,
      ):
        emit(
          state.copyWith(saveStatus: RequestStatus.success, settings: settings),
        );
    }
  }
}
