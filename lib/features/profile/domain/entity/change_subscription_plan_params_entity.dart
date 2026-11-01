import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';

final class ChangeSubscriptionPlanParamsEntity extends Equatable {
  const ChangeSubscriptionPlanParamsEntity({required this.plan});

  final SubscriptionPlan plan;

  @override
  List<Object?> get props => <Object?>[plan];
}
