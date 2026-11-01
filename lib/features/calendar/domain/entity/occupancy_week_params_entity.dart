import 'package:equatable/equatable.dart';

final class OccupancyWeekParamsEntity extends Equatable {
  const OccupancyWeekParamsEntity({required this.favoritesOnly, this.date});

  /// Any day of the week to load; `null` means the source's current week.
  final DateTime? date;

  /// Only rows of favorite properties.
  final bool favoritesOnly;

  @override
  List<Object?> get props => <Object?>[date, favoritesOnly];
}
