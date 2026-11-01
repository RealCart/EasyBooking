import 'package:equatable/equatable.dart';

/// How the signing link reaches the guest.
enum ContractDeliveryChannel {
  sms,
  whatsApp,
  email;

  /// Whether [ContractRecipientEntity.address] is a phone number.
  bool get usesPhone => this != email;
}

/// Where the signing link is sent.
final class ContractRecipientEntity extends Equatable {
  const ContractRecipientEntity({required this.channel, required this.address});

  final ContractDeliveryChannel channel;

  /// A phone number in E.164 format (`+77005124521`) for [channel]s that
  /// [ContractDeliveryChannel.usesPhone], otherwise an email address.
  final String address;

  @override
  List<Object?> get props => <Object?>[channel, address];
}
