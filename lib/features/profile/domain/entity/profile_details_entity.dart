import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';

/// The editable data of «Редактировать профиль»: personal data and the
/// workspace.
final class ProfileDetailsEntity extends Equatable {
  const ProfileDetailsEntity({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.teamName,
    required this.city,
  });

  final String firstName;
  final String lastName;

  /// The sign-in phone in E.164, such as `+77012345678`. Read-only here: it
  /// changes only through a verified flow.
  final String phone;
  final String email;

  /// Workspace name, such as `EasyBooking Алматы`.
  final String teamName;

  /// The workspace city; its [CityEntity.utcOffset] is the time zone.
  final CityEntity city;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => <Object?>[
    firstName,
    lastName,
    phone,
    email,
    teamName,
    city,
  ];
}
