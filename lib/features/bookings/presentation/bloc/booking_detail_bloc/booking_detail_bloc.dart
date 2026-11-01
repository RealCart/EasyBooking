import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/bookings/domain/entity/booking_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/cancel_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/entity/get_booking_params_entity.dart';
import 'package:easy_booking/features/bookings/domain/usecases/cancel_booking_usecase.dart';
import 'package:easy_booking/features/bookings/domain/usecases/get_booking_usecase.dart';

part 'booking_detail_event.dart';
part 'booking_detail_state.dart';

/// One booking on «Бронирование».
final class BookingDetailBloc
    extends Bloc<BookingDetailEvent, BookingDetailState> {
  BookingDetailBloc({required this._getBooking, required this._cancelBooking})
    : super(const BookingDetailState()) {
    on<BookingDetailRequested>(_onRequested, transformer: restartable());
    on<BookingDetailCancelRequested>(
      _onCancelRequested,
      transformer: droppable(),
    );
  }

  final GetBookingUsecase _getBooking;
  final CancelBookingUsecase _cancelBooking;

  Future<void> _onRequested(
    BookingDetailRequested event,
    Emitter<BookingDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        bookingId: event.bookingId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, BookingEntity> result = await _getBooking(
      GetBookingParamsEntity(bookingId: event.bookingId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, BookingEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, BookingEntity>(value: final BookingEntity booking):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, booking: booking),
        );
    }
  }

  /// Shows the booking the source returned after cancelling it.
  Future<void> _onCancelRequested(
    BookingDetailCancelRequested event,
    Emitter<BookingDetailState> emit,
  ) async {
    final BookingEntity? booking = state.booking;
    if (booking == null || !booking.status.isCancellable) {
      return;
    }
    emit(
      state.copyWith(
        cancelStatus: RequestStatus.loading,
        resetCancelFailure: true,
      ),
    );

    final Either<Failure, BookingEntity> result = await _cancelBooking(
      CancelBookingParamsEntity(bookingId: booking.id),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, BookingEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            cancelStatus: RequestStatus.failure,
            cancelFailure: failure,
          ),
        );
      case Right<Failure, BookingEntity>(value: final BookingEntity cancelled):
        emit(
          state.copyWith(
            cancelStatus: RequestStatus.success,
            // Another booking may have been requested meanwhile.
            booking: state.bookingId == cancelled.id ? cancelled : null,
          ),
        );
    }
  }
}
