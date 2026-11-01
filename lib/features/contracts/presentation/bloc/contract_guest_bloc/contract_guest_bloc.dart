import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/get_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';

part 'contract_guest_event.dart';
part 'contract_guest_state.dart';

/// «Новый договор · 1 из 2 · Проверим данные гостя».
final class ContractGuestBloc
    extends Bloc<ContractGuestEvent, ContractGuestState> {
  ContractGuestBloc({required this._getContract, required this._updateGuest})
    : super(const ContractGuestState()) {
    on<ContractGuestRequested>(_onRequested, transformer: restartable());
    on<ContractGuestFieldEdited>(_onFieldEdited);
    on<ContractGuestSubmitted>(_onSubmitted, transformer: droppable());
  }

  /// Fields shown on the screen. An error keyed by anything else would be
  /// invisible, so it is also reported as [ContractGuestState.submitFailure].
  static const Set<String> _displayedFields = <String>{
    ContractGuestFields.firstName,
    ContractGuestFields.lastName,
    ContractGuestFields.patronymic,
    ContractGuestFields.iin,
    ContractGuestFields.idNumber,
  };

  final GetContractUsecase _getContract;
  final UpdateContractGuestUsecase _updateGuest;

  /// Keeps the shown contract while loading and after a failed reload.
  Future<void> _onRequested(
    ContractGuestRequested event,
    Emitter<ContractGuestState> emit,
  ) async {
    emit(
      state.copyWith(
        contractId: event.contractId,
        loadStatus: RequestStatus.loading,
        resetLoadFailure: true,
      ),
    );

    final Either<Failure, ContractEntity> result = await _getContract(
      GetContractParamsEntity(contractId: event.contractId),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ContractEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, ContractEntity>(value: final ContractEntity contract):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.success,
            contract: contract,
          ),
        );
    }
  }

  /// Hides the server error of the edited field and the general failure.
  void _onFieldEdited(
    ContractGuestFieldEdited event,
    Emitter<ContractGuestState> emit,
  ) {
    final bool hasFieldError = state.fieldErrors.containsKey(event.field);
    if (!hasFieldError &&
        state.submitFailure == null &&
        !state.submitStatus.isFailure) {
      return;
    }
    emit(
      state.copyWith(
        submitStatus: state.submitStatus.isFailure
            ? RequestStatus.initial
            : null,
        resetSubmitFailure: true,
        fieldErrors: hasFieldError
            ? Map<String, String>.unmodifiable(
                Map<String, String>.of(state.fieldErrors)..remove(event.field),
              )
            : null,
      ),
    );
  }

  /// On success the screen opens «Условия и подпись». Submitting again after
  /// coming back is allowed while the contract is unsigned.
  Future<void> _onSubmitted(
    ContractGuestSubmitted event,
    Emitter<ContractGuestState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: RequestStatus.loading,
        resetSubmitFailure: true,
        fieldErrors: const <String, String>{},
      ),
    );

    final Either<Failure, ContractEntity> result = await _updateGuest(
      event.params,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ContractEntity>(value: final ValidationFailure failure)
          when failure.fieldErrors.isNotEmpty:
        final bool isDisplayed = failure.fieldErrors.keys.any(
          _displayedFields.contains,
        );
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            fieldErrors: Map<String, String>.unmodifiable(failure.fieldErrors),
            submitFailure: isDisplayed ? null : failure,
          ),
        );
      case Left<Failure, ContractEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.failure,
            submitFailure: failure,
          ),
        );
      case Right<Failure, ContractEntity>(value: final ContractEntity contract):
        emit(
          state.copyWith(
            submitStatus: RequestStatus.success,
            contract: contract,
          ),
        );
    }
  }
}
