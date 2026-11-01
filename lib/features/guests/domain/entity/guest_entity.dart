import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/guests/domain/entity/guest_contract_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_document_entity.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_gender.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_initials.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_stay_entity.dart';

/// A guest with their documents, stays, and contracts («Гость»).
final class GuestEntity extends Equatable {
  const GuestEntity({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.stays,
    required this.contracts,
    this.document,
  });

  final String id;
  final String fullName;

  /// International format, such as `+7 701 245 18 92`.
  final String phone;
  final GuestGender gender;

  /// `null` when the guest has not uploaded a document.
  final GuestDocumentEntity? document;

  /// Newest check-in first.
  final List<GuestStayEntity> stays;

  /// Newest first.
  final List<GuestContractEntity> contracts;

  /// Up to two capital letters, such as `АС` for «Айжан Сарсенова».
  String get initials => initialsOf(fullName);

  @override
  List<Object?> get props => <Object?>[
    id,
    fullName,
    phone,
    gender,
    document,
    stays,
    contracts,
  ];
}
