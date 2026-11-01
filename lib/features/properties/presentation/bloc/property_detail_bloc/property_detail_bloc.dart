import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/set_property_favorite_params_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';

part 'property_detail_event.dart';
part 'property_detail_state.dart';

/// One property on «Ваш объект».
final class PropertyDetailBloc
    extends Bloc<PropertyDetailEvent, PropertyDetailState> {
  PropertyDetailBloc({required this._getProperty, required this._setFavorite})
    : super(const PropertyDetailState()) {
    on<PropertyDetailRequested>(_onRequested, transformer: restartable());
    on<PropertyDetailFavoriteToggled>(
      _onFavoriteToggled,
      transformer: droppable(),
    );
  }

  final GetPropertyUsecase _getProperty;
  final SetPropertyFavoriteUsecase _setFavorite;

  Future<void> _onRequested(
    PropertyDetailRequested event,
    Emitter<PropertyDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        propertyId: event.propertyId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, PropertyEntity> result = await _getProperty(
      GetPropertyParamsEntity(propertyId: event.propertyId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, PropertyEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, PropertyEntity>(value: final PropertyEntity property):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            property: property,
          ),
        );
    }
  }

  /// Flips the heart after the source confirmed the write.
  Future<void> _onFavoriteToggled(
    PropertyDetailFavoriteToggled event,
    Emitter<PropertyDetailState> emit,
  ) async {
    final PropertyEntity? property = state.property;
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
        emit(
          state.copyWith(
            property: property.copyWith(isFavorite: isFavorite),
          ),
        );
    }
  }
}
