import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/bloc/event_transformers.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/usecase/usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/change_subscription_plan_params_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';

part 'billing_event.dart';
part 'billing_state.dart';

/// «Тариф и оплата»: the subscription overview and switching plans.
final class BillingBloc extends Bloc<BillingEvent, BillingState> {
  BillingBloc({
    required this._getBillingOverview,
    required this._changeSubscriptionPlan,
  }) : super(const BillingState()) {
    on<BillingRequested>(_onRequested, transformer: restartable());
    on<BillingPlanChangeRequested>(
      _onPlanChangeRequested,
      transformer: droppable(),
    );
  }

  final GetBillingOverviewUsecase _getBillingOverview;
  final ChangeSubscriptionPlanUsecase _changeSubscriptionPlan;

  /// Bumped by every successful plan change, so a load that started
  /// earlier does not replace the newer overview.
  int _writeCount = 0;

  Future<void> _onRequested(
    BillingRequested event,
    Emitter<BillingState> emit,
  ) async {
    final int writeCount = _writeCount;
    emit(
      state.copyWith(loadStatus: RequestStatus.loading, resetLoadFailure: true),
    );

    final Either<Failure, BillingOverviewEntity> result =
        await _getBillingOverview(const NoParams());
    if (emit.isDone) {
      return;
    }
    if (writeCount != _writeCount) {
      emit(state.copyWith(loadStatus: RequestStatus.success));
      return;
    }
    switch (result) {
      case Left<Failure, BillingOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            loadStatus: RequestStatus.failure,
            loadFailure: failure,
          ),
        );
      case Right<Failure, BillingOverviewEntity>(
        value: final BillingOverviewEntity overview,
      ):
        emit(
          state.copyWith(loadStatus: RequestStatus.success, overview: overview),
        );
    }
  }

  Future<void> _onPlanChangeRequested(
    BillingPlanChangeRequested event,
    Emitter<BillingState> emit,
  ) async {
    emit(
      state.copyWith(
        changePlanStatus: RequestStatus.loading,
        resetChangePlanFailure: true,
      ),
    );

    final Either<Failure, BillingOverviewEntity> result =
        await _changeSubscriptionPlan(
          ChangeSubscriptionPlanParamsEntity(plan: event.plan),
        );
    if (emit.isDone) {
      return;
    }
    switch (result) {
      case Left<Failure, BillingOverviewEntity>(value: final Failure failure):
        emit(
          state.copyWith(
            changePlanStatus: RequestStatus.failure,
            changePlanFailure: failure,
          ),
        );
      case Right<Failure, BillingOverviewEntity>(
        value: final BillingOverviewEntity overview,
      ):
        _writeCount += 1;
        emit(
          state.copyWith(
            changePlanStatus: RequestStatus.success,
            overview: overview,
          ),
        );
    }
  }
}
