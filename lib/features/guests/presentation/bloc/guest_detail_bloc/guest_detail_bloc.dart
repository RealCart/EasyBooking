import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/guests/domain/entity/create_guest_contract_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/get_guest_params_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_entity.dart';
import 'package:easy_booking/features/guests/domain/usecases/create_guest_contract_usecase.dart';
import 'package:easy_booking/features/guests/domain/usecases/get_guest_usecase.dart';

part 'guest_detail_event.dart';
part 'guest_detail_state.dart';

/// One guest on «Гость».
final class GuestDetailBloc extends Bloc<GuestDetailEvent, GuestDetailState> {
  GuestDetailBloc({required this._getGuest, required this._createContract})
    : super(const GuestDetailState()) {
    on<GuestDetailRequested>(_onRequested, transformer: restartable());
    // «Создать договор» must not start two drafts.
    on<GuestContractCreationRequested>(
      _onContractCreationRequested,
      transformer: droppable(),
    );
  }

  final GetGuestUsecase _getGuest;
  final CreateGuestContractUsecase _createContract;

  Future<void> _onRequested(
    GuestDetailRequested event,
    Emitter<GuestDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        guestId: event.guestId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, GuestEntity> result = await _getGuest(
      GetGuestParamsEntity(guestId: event.guestId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, GuestEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, GuestEntity>(value: final GuestEntity guest):
        emit(state.copyWith(loadStatus: RequestStatus.success, guest: guest));
    }
  }

  /// On success [GuestDetailState.createdContractId] holds the draft to
  /// open.
  Future<void> _onContractCreationRequested(
    GuestContractCreationRequested event,
    Emitter<GuestDetailState> emit,
  ) async {
    final GuestEntity? guest = state.guest;
    if (guest == null) {
      return;
    }
    emit(
      state.copyWith(
        createContractStatus: RequestStatus.loading,
        resetCreatedContractId: true,
        resetCreateContractFailure: true,
      ),
    );

    final Either<Failure, String> result = await _createContract(
      CreateGuestContractParamsEntity(guestId: guest.id),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, String>(value: final Failure failure):
        emit(
          state.copyWith(
            createContractStatus: RequestStatus.failure,
            createContractFailure: failure,
          ),
        );
      case Right<Failure, String>(value: final String contractId):
        emit(
          state.copyWith(
            createContractStatus: RequestStatus.success,
            createdContractId: contractId,
          ),
        );
    }
  }
}
