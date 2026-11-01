import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';

/// Input of `UpdateProfileUsecase`: the «Редактировать профиль» form.
final class UpdateProfileParamsEntity extends Equatable {
  const UpdateProfileParamsEntity({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.teamName,
    required this.city,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String teamName;
  final CityEntity city;

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    email,
    teamName,
    city,
  ];
}
