import 'package:equatable/equatable.dart';

/// How much of a plan limit is used, such as `4 из 10` properties.
final class PlanUsageEntity extends Equatable {
  const PlanUsageEntity({required this.used, required this.limit});

  final int used;

  /// Greater than zero.
  final int limit;

  /// Share of the limit in use, from 0 to 1, for a progress bar.
  double get fraction => (used / limit).clamp(0, 1).toDouble();

  bool get isAtLimit => used >= limit;

  @override
  List<Object?> get props => <Object?>[used, limit];
}
