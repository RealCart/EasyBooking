import 'package:equatable/equatable.dart';

final class CalendarDayParamsEntity extends Equatable {
  const CalendarDayParamsEntity({required this.favoritesOnly, this.date});

  /// The day to load; `null` means the source's today.
  final DateTime? date;

  /// Only events of favorite properties.
  final bool favoritesOnly;

  @override
  List<Object?> get props => <Object?>[date, favoritesOnly];
}
