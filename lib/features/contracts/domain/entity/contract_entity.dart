import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/contracts/domain/entity/contract_file_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_history_entry_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_stay_entity.dart';

enum ContractStatus {
  /// Not sent yet, or the guest data changed after sending.
  draft,

  /// The link was sent; the guest has not opened it.
  sent,

  /// The guest opened the link but has not signed.
  opened,

  signed;

  bool get isSigned => this == signed;

  /// Sent and not signed yet: «Ожидает подписи гостя».
  bool get isAwaitingSignature => this == sent || this == opened;

  /// Guest data can be changed and the contract (re)sent until it is signed.
  bool get canSend => this != signed;
}

/// A rental contract between the host and a guest.
final class ContractEntity extends Equatable {
  const ContractEntity({
    required this.id,
    required this.number,
    required this.status,
    required this.guest,
    required this.isGuestDataRecognized,
    required this.stay,
    required this.document,
    required this.recipient,
    required this.history,
    required this.receivedAt,
    this.identityDocument,
    this.signingUrl,
    this.remindAt,
  });

  final String id;

  /// «EB-1052», shown as «Договор № EB-1052».
  final String number;
  final ContractStatus status;
  final ContractGuestEntity guest;

  /// The scanned identity document the guest data was read from; `null`
  /// when the data was typed by hand.
  final ContractFileEntity? identityDocument;

  /// Whether [guest] was recognized from [identityDocument]
  /// («Данные распознаны. Сверьте с документом.»).
  final bool isGuestDataRecognized;
  final ContractStayEntity stay;

  /// The contract file («Договор найма»).
  final ContractFileEntity document;

  /// Where the signing link goes: the last used recipient, or the guest's
  /// phone by SMS before the first send.
  final ContractRecipientEntity recipient;

  /// Completed steps, oldest first.
  final List<ContractHistoryEntryEntity> history;

  /// The current signing link; `null` while [status] is
  /// [ContractStatus.draft].
  final String? signingUrl;

  /// When the guest gets an automatic reminder; `null` when none is
  /// scheduled (draft or signed).
  final DateTime? remindAt;

  /// When this contract was read. Relative times («через 2 часа»,
  /// «Сегодня») are measured from it.
  final DateTime receivedAt;

  ContractEntity copyWith({
    ContractStatus? status,
    ContractGuestEntity? guest,
    ContractRecipientEntity? recipient,
    List<ContractHistoryEntryEntity>? history,
    String? signingUrl,
    bool resetSigningUrl = false,
    DateTime? remindAt,
    bool resetRemindAt = false,
    DateTime? receivedAt,
  }) {
    return ContractEntity(
      id: id,
      number: number,
      status: status ?? this.status,
      guest: guest ?? this.guest,
      identityDocument: identityDocument,
      isGuestDataRecognized: isGuestDataRecognized,
      stay: stay,
      document: document,
      recipient: recipient ?? this.recipient,
      history: history ?? this.history,
      signingUrl: resetSigningUrl ? null : signingUrl ?? this.signingUrl,
      remindAt: resetRemindAt ? null : remindAt ?? this.remindAt,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    number,
    status,
    guest,
    identityDocument,
    isGuestDataRecognized,
    stay,
    document,
    recipient,
    history,
    signingUrl,
    remindAt,
    receivedAt,
  ];
}
