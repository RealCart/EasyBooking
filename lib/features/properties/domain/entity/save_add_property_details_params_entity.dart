import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/property_type.dart';

/// Step 1 of «Добавить квартиру».
final class SaveAddPropertyDetailsParamsEntity extends Equatable {
  const SaveAddPropertyDetailsParamsEntity({
    required this.title,
    required this.address,
    required this.type,
    required this.rooms,
  });

  /// The «Название» field, such as `Esentai City · 84`.
  final String title;
  final String address;
  final PropertyType type;
  final int rooms;

  @override
  List<Object?> get props => <Object?>[title, address, type, rooms];
}
