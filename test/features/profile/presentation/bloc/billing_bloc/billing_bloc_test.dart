import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/billing_bloc/billing_bloc.dart';

import '../../../../../helpers/fake_profile_repository.dart';

const Failure _failure = ConnectionFailure();

final BillingOverviewEntity _pro = testBillingOverview();
final BillingOverviewEntity _free = testBillingOverview(
  plan: SubscriptionPlan.free,
  memberCount: 2,
);

/// A [BillingBloc] over a [FakeProfileRepository] that records its states.
final class _Subject {
  _Subject() {
    repository.changePlanResult = Right<Failure, BillingOverviewEntity>(_free);
    bloc = BillingBloc(
      getBillingOverview: GetBillingOverviewUsecase(repository),
      changeSubscriptionPlan: ChangeSubscriptionPlanUsecase(repository),
    );
    final StreamSubscription<BillingState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);
    addTearDown(bloc.close);
  }

  final FakeProfileRepository repository = FakeProfileRepository();
  late final BillingBloc bloc;
  final List<BillingState> states = <BillingState>[];

  Future<void> add(BillingEvent event) async {
    bloc.add(event);
    await pumpEventQueue();
  }

  Future<void> load() async {
    await add(const BillingRequested());
    states.clear();
  }
}

void main() {
  group('BillingBloc load', () {
    test('starts empty', () {
      expect(_Subject().bloc.state, const BillingState());
    });

    test('a load emits loading, then the overview', () async {
      final _Subject subject = _Subject();

      await subject.add(const BillingRequested());

      expect(subject.states, <BillingState>[
        const BillingState(loadStatus: RequestStatus.loading),
        BillingState(loadStatus: RequestStatus.success, overview: _pro),
      ]);
    });

    test('a failed load emits the failure; a retry clears it', () async {
      final _Subject subject = _Subject();
      subject.repository.billingResult =
          const Left<Failure, BillingOverviewEntity>(_failure);

      await subject.add(const BillingRequested());

      expect(
        subject.bloc.state,
        const BillingState(
          loadStatus: RequestStatus.failure,
          loadFailure: _failure,
        ),
      );

      subject.repository.billingResult = Right<Failure, BillingOverviewEntity>(
        _pro,
      );
      subject.states.clear();
      await subject.add(const BillingRequested());

      expect(subject.states.first.loadFailure, isNull);
      expect(subject.bloc.state.overview, _pro);
    });

    test('the latest load wins when an older one completes last', () async {
      final _Subject subject = _Subject();
      subject.repository.holdBilling = true;
      await subject.add(const BillingRequested());
      await subject.add(const BillingRequested());

      subject.repository.heldBilling[1].complete(
        Right<Failure, BillingOverviewEntity>(_pro),
      );
      await pumpEventQueue();
      subject.repository.heldBilling[0].complete(
        Right<Failure, BillingOverviewEntity>(_free),
      );
      await pumpEventQueue();

      expect(subject.bloc.state.overview, _pro);
    });

    test(
      'a load that started before a plan change keeps the new plan',
      () async {
        final _Subject subject = _Subject();
        await subject.load();
        subject.repository.holdBilling = true;
        await subject.add(const BillingRequested());

        await subject.add(
          const BillingPlanChangeRequested(SubscriptionPlan.free),
        );
        subject.repository.heldBilling.single.complete(
          Right<Failure, BillingOverviewEntity>(_pro),
        );
        await pumpEventQueue();

        expect(subject.bloc.state.overview, _free);
        expect(subject.bloc.state.loadStatus, RequestStatus.success);
      },
    );

    test('a load completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      subject.repository.holdBilling = true;
      await subject.add(const BillingRequested());
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldBilling.single.complete(
        Right<Failure, BillingOverviewEntity>(_pro),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });

  group('BillingBloc plan change', () {
    test('emits changing, then the new overview', () async {
      final _Subject subject = _Subject();
      await subject.load();

      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );

      expect(subject.states, <BillingState>[
        BillingState(
          loadStatus: RequestStatus.success,
          overview: _pro,
          changePlanStatus: RequestStatus.loading,
        ),
        BillingState(
          loadStatus: RequestStatus.success,
          overview: _free,
          changePlanStatus: RequestStatus.success,
        ),
      ]);
      expect(subject.repository.changedPlans, <SubscriptionPlan>[
        SubscriptionPlan.free,
      ]);
    });

    test('a plan limit failure keeps the overview', () async {
      final _Subject subject = _Subject();
      await subject.load();
      const Failure failure = ValidationFailure(
        code: ProfileErrorCodes.planLimitExceeded,
      );
      subject.repository.changePlanResult =
          const Left<Failure, BillingOverviewEntity>(failure);

      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );

      expect(subject.bloc.state.changePlanStatus, RequestStatus.failure);
      expect(subject.bloc.state.changePlanFailure, failure);
      expect(subject.bloc.state.overview, _pro);
    });

    test('a new change clears the earlier failure', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.changePlanResult =
          const Left<Failure, BillingOverviewEntity>(_failure);
      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );
      subject.repository.changePlanResult =
          Right<Failure, BillingOverviewEntity>(_free);
      subject.states.clear();

      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );

      expect(subject.states.first.changePlanFailure, isNull);
      expect(subject.bloc.state.changePlanStatus, RequestStatus.success);
    });

    test('a second change while changing is dropped', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdChangePlan = true;

      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );
      await subject.add(const BillingPlanChangeRequested(SubscriptionPlan.pro));
      subject.repository.heldChangePlan.single.complete(
        Right<Failure, BillingOverviewEntity>(_free),
      );
      await pumpEventQueue();

      expect(subject.repository.changedPlans, <SubscriptionPlan>[
        SubscriptionPlan.free,
      ]);
    });

    test('a change completing after close emits nothing', () async {
      final _Subject subject = _Subject();
      await subject.load();
      subject.repository.holdChangePlan = true;
      await subject.add(
        const BillingPlanChangeRequested(SubscriptionPlan.free),
      );
      final int emitted = subject.states.length;

      await subject.bloc.close();
      subject.repository.heldChangePlan.single.complete(
        Right<Failure, BillingOverviewEntity>(_free),
      );
      await pumpEventQueue();

      expect(subject.states, hasLength(emitted));
    });
  });
}
