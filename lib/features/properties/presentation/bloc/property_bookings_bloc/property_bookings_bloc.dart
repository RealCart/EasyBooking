import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/get_property_params_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_booking_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_bookings_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_property_bookings_usecase.dart';

part 'property_bookings_event.dart';
part 'property_bookings_state.dart';

/// The «Брони» tab of one property.
final class PropertyBookingsBloc
    extends Bloc<PropertyBookingsEvent, PropertyBookingsState> {
  PropertyBookingsBloc({required this._getBookings})
    : super(const PropertyBookingsState()) {
    // Latest wins: a retry replaces a load that is still running.
    on<PropertyBookingsRequested>(_onRequested, transformer: restartable());
    on<PropertyBookingsPeriodSelected>(_onPeriodSelected);
  }

  final GetPropertyBookingsUsecase _getBookings;

  /// Keeps the shown bookings while loading and after a failed refresh.
  Future<void> _onRequested(
    PropertyBookingsRequested event,
    Emitter<PropertyBookingsState> emit,
  ) async {
    emit(
      state.copyWith(
        propertyId: event.propertyId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, PropertyBookingsEntity> result = await _getBookings(
      GetPropertyParamsEntity(propertyId: event.propertyId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, PropertyBookingsEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, PropertyBookingsEntity>(
        value: final PropertyBookingsEntity bookings,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, bookings: bookings),
        );
    }
  }

  void _onPeriodSelected(
    PropertyBookingsPeriodSelected event,
    Emitter<PropertyBookingsState> emit,
  ) {
    emit(state.copyWith(period: event.period));
  }
}
