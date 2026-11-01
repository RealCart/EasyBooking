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

part 'contract_status_event.dart';
part 'contract_status_state.dart';

/// «Договор · статус»: signing progress and resending the link.
final class ContractStatusBloc
    extends Bloc<ContractStatusEvent, ContractStatusState> {
  ContractStatusBloc({required this._getContract, required this._sendContract})
    : super(const ContractStatusState()) {
    on<ContractStatusRequested>(_onRequested, transformer: restartable());
    on<ContractResendRequested>(_onResendRequested, transformer: droppable());
  }

  final GetContractUsecase _getContract;
  final SendContractUsecase _sendContract;

  /// Bumped by every successful resend, so a load that started earlier does
  /// not replace the newer contract.
  int _writeCount = 0;

  /// Keeps the shown contract while loading and after a failed reload.
  Future<void> _onRequested(
    ContractStatusRequested event,
    Emitter<ContractStatusState> emit,
  ) async {
    final int writeCount = _writeCount;
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
    if (writeCount != _writeCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
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

  /// «Отправить повторно»: a new link to the last recipient. The contract
  /// changes after the source confirmed the send.
  Future<void> _onResendRequested(
    ContractResendRequested event,
    Emitter<ContractStatusState> emit,
  ) async {
    final ContractEntity? contract = state.contract;
    if (contract == null || !contract.status.canSend) {
      return;
    }
    emit(
      state.copyWith(
        resendStatus: RequestStatus.loading,
        resetResendFailure: true,
      ),
    );

    final Either<Failure, ContractEntity> result = await _sendContract(
      SendContractParamsEntity(
        contractId: contract.id,
        channel: contract.recipient.channel,
        address: contract.recipient.address,
      ),
    );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, ContractEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            resendStatus: RequestStatus.failure,
            resendFailure: failure,
          ),
        );
      case Right<Failure, ContractEntity>(value: final ContractEntity sent):
        _writeCount += 1;
        emit(
          state.copyWith(resendStatus: RequestStatus.success, contract: sent),
        );
    }
  }
}
