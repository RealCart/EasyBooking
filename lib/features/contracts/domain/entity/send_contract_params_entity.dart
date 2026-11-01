import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';

/// Sends the signing link of [contractId] through [channel] to [address].
final class SendContractParamsEntity extends Equatable {
  const SendContractParamsEntity({
    required this.contractId,
    required this.channel,
    required this.address,
  });

  final String contractId;
  final ContractDeliveryChannel channel;

  /// A phone number in any user-typed format for [channel]s that
  /// [ContractDeliveryChannel.usesPhone], otherwise an email address.
  final String address;

  @override
  List<Object?> get props => <Object?>[contractId, channel, address];
}
