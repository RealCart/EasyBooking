import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_list_options.dart';
import 'package:easy_booking/features/properties/domain/entity/set_property_favorite_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';

part 'properties_event.dart';
part 'properties_state.dart';

/// The property list of «Ваши объекты» and «Избранные».
final class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  PropertiesBloc({required this._getProperties, required this._setFavorite})
    : super(const PropertiesState()) {
    // Latest wins: a refresh replaces a load that is still running.
    on<PropertiesRequested>(_onRequested, transformer: restartable());
    on<PropertiesFilterSelected>(_onFilterSelected);
    on<PropertiesQueryChanged>(_onQueryChanged);
    on<PropertiesSortSelected>(_onSortSelected);
    // One write at a time, so quick taps on one heart apply in order.
    on<PropertyFavoriteToggled>(_onFavoriteToggled, transformer: sequential());
  }

  final GetPropertiesUsecase _getProperties;
  final SetPropertyFavoriteUsecase _setFavorite;

  /// Bumped by every successful favourite write, so a load that started
  /// earlier does not flip the heart back.
  int _writeCount = 0;

  /// Keeps the shown list while loading and after a failed refresh.
  Future<void> _onRequested(
    PropertiesRequested event,
    Emitter<PropertiesState> emit,
  ) async {
    final int writeCount = _writeCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, List<PropertyEntity>> result = await _getProperties(
      const NoParams(),
    );
    if (emit.isDone) {
      return;
    }
    if (writeCount != _writeCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, List<PropertyEntity>>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, List<PropertyEntity>>(
        value: final List<PropertyEntity> properties,
      ):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            properties: List<PropertyEntity>.unmodifiable(properties),
          ),
        );
    }
  }

  void _onFilterSelected(
    PropertiesFilterSelected event,
    Emitter<PropertiesState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onQueryChanged(
    PropertiesQueryChanged event,
    Emitter<PropertiesState> emit,
  ) {
    emit(state.copyWith(query: event.query));
  }

  void _onSortSelected(
    PropertiesSortSelected event,
    Emitter<PropertiesState> emit,
  ) {
    emit(state.copyWith(sort: event.sort));
  }

  /// Flips the heart after the source confirmed the write.
  Future<void> _onFavoriteToggled(
    PropertyFavoriteToggled event,
    Emitter<PropertiesState> emit,
  ) async {
    final PropertyEntity? property = state.propertyById(event.propertyId);
    if (property == null) {
      return;
    }
    final bool isFavorite = !property.isFavorite;
    emit(state.copyWith(resetFavoriteFailure: true));

    final Either<Failure, void> result = await _setFavorite(
      SetPropertyFavoriteParamsEntity(
        propertyId: property.id,
        isFavorite: isFavorite,
      ),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, void>(value: final Failure failure):
        emit(state.copyWith(favoriteFailure: failure));
      case Right<Failure, void>():
        _writeCount += 1;
        emit(
          state.copyWith(
            properties: List<PropertyEntity>.unmodifiable(
              state.properties.map(
                (PropertyEntity item) => item.id == property.id
                    ? item.copyWith(isFavorite: isFavorite)
                    : item,
              ),
            ),
          ),
        );
    }
  }
}
