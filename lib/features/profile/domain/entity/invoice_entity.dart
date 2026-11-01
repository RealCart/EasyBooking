import 'package:equatable/equatable.dart';

/// A monthly subscription invoice («Счёт за октябрь»).
final class InvoiceEntity extends Equatable {
  const InvoiceEntity({
    required this.id,
    required this.period,
    required this.amount,
  });

  final String id;

  /// The first day of the billed month.
  final DateTime period;

  /// In tenge.
  final int amount;

  @override
  List<Object?> get props => <Object?>[id, period, amount];
}
