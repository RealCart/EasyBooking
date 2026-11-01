import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_gender.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_initials.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';

/// One row of the guest list.
final class GuestSummaryEntity extends Equatable {
  const GuestSummaryEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.gender,
    this.latestStay,
    this.latestContractStatus,
  });

  /// Opens `AppRoutes.guest`.
  final String id;
  final String fullName;

  /// International format, such as `+7 701 245 18 92`.
  final String phone;
  final GuestGender gender;

  /// The newest stay by check-in; `null` when the guest has none.
  final GuestStayEntity? latestStay;

  /// The status of the newest contract; `null` when there is no contract
  /// («Нет договора»).
  final GuestContractStatus? latestContractStatus;

  /// Up to two capital letters, such as `АС` for «Айжан Сарсенова».
  String get initials => initialsOf(fullName);

  @override
  List<Object?> get props => <Object?>[
    id,
    fullName,
    phone,
    gender,
    latestStay,
    latestContractStatus,
  ];
}
