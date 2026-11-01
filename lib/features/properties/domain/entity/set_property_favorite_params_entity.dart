import 'package:equatable/equatable.dart';

final class SetPropertyFavoriteParamsEntity extends Equatable {
  const SetPropertyFavoriteParamsEntity({
    required this.propertyId,
    required this.isFavorite,
  });

  final String propertyId;
  final bool isFavorite;

  @override
  List<Object?> get props => <Object?>[propertyId, isFavorite];
}
