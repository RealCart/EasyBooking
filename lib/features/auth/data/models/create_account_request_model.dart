import 'package:json_annotation/json_annotation.dart';

import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';

part 'create_account_request_model.g.dart';

/// Body of `POST /auth/account`.
@JsonSerializable(createFactory: false)
final class CreateAccountRequestModel {
  const CreateAccountRequestModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.teamName,
    required this.city,
    required this.timeZone,
  });

  factory CreateAccountRequestModel.fromEntity(
    CreateAccountParamsEntity params,
  ) {
    return CreateAccountRequestModel(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      teamName: params.teamName,
      city: params.city.id,
      timeZone: params.city.timeZone,
    );
  }

  final String firstName;

  final String lastName;

  final String email;

  final String teamName;

  /// Id of the picked city.
  final String city;

  /// IANA id of the city's time zone.
  final String timeZone;

  Map<String, dynamic> toJson() => _$CreateAccountRequestModelToJson(this);
}
