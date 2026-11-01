import 'package:equatable/equatable.dart';

/// Input of `SearchBookingGuestsUsecase`: «Найти существующего гостя».
final class SearchBookingGuestsParamsEntity extends Equatable {
  const SearchBookingGuestsParamsEntity({required this.query});

  /// Part of a name or of a phone number.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}
