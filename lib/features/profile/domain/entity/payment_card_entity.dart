import 'package:equatable/equatable.dart';

enum PaymentCardBrand { visa, mastercard }

/// The card the subscription is charged to.
final class PaymentCardEntity extends Equatable {
  const PaymentCardEntity({required this.brand, required this.lastDigits});

  final PaymentCardBrand brand;

  /// The last four digits, such as `4218`.
  final String lastDigits;

  @override
  List<Object?> get props => <Object?>[brand, lastDigits];
}
