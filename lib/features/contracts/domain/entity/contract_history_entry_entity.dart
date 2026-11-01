import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';

enum ContractHistoryKind { created, sent, opened, signed }

/// One completed step on the contract timeline («История»).
final class ContractHistoryEntryEntity extends Equatable {
  const ContractHistoryEntryEntity({
    required this.kind,
    required this.at,
    this.recipient,
  });

  final ContractHistoryKind kind;
  final DateTime at;

  /// Where the link went; set only for [ContractHistoryKind.sent].
  final ContractRecipientEntity? recipient;

  @override
  List<Object?> get props => <Object?>[kind, at, recipient];
}
