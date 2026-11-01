part of 'billing_bloc.dart';

sealed class BillingEvent extends Equatable {
  const BillingEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Loads the overview: added when the BLoC is created, on retry, and on
/// pull-to-refresh.
final class BillingRequested extends BillingEvent {
  const BillingRequested();
}

/// The user chose [plan] under «Управлять тарифом».
final class BillingPlanChangeRequested extends BillingEvent {
  const BillingPlanChangeRequested(this.plan);

  final SubscriptionPlan plan;

  @override
  List<Object?> get props => <Object?>[plan];
}
