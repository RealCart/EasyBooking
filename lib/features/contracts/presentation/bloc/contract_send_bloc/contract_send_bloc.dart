import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/get_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';

part 'contract_send_event.dart';
part 'contract_send_state.dart';

/// «Новый договор · 2 из 2 · Условия и подпись».
final class ContractSendBloc
    extends Bloc<ContractSendEvent, ContractSendState> {
  ContractSendBloc({required this._getContract, required this._sendContract})
    : super(const ContractSendState()) {
    on<ContractSendRequested>(_onRequested, transformer: restartable());
    on<ContractSendSubmitted>(_onSubmitted, transformer: droppable());
  }

  final GetContractUsecase _getContract;
  final SendContractUsecase _sendContract;

  /// Keeps the shown contract while loading and after a failed reload.
  Future<void> _onRequested(
    ContractSendRequested event,
    Emitter<ContractSendState> emit,
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

  /// On success the screen opens the contract status.
  Future<void> _onSubmitted(
    ContractSendSubmitted event,
    Emitter<ContractSendState> emit,
  ) async {
    emit(
      state.copyWith(
        sendStatus: RequestStatus.loading,
        resetSendFailure: true,
      ),
    );

    final Either<Failure, ContractEntity> result = await _sendContract(
      event.params,
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ContractEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            sendStatus: RequestStatus.failure,
            sendFailure: failure,
          ),
        );
      case Right<Failure, ContractEntity>(value: final ContractEntity contract):
        emit(
          state.copyWith(sendStatus: RequestStatus.success, contract: contract),
        );
    }
  }
}
