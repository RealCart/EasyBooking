import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';

/// Body of `POST /auth/account`.
final class CreateAccountRequestModel {
  const CreateAccountRequestModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.teamName,
    required this.cityId,
    required this.timeZone,
  });

  /// [params] must come from `CreateAccountUsecase`, which guarantees a city;
  /// a missing city is a programming error.
  factory CreateAccountRequestModel.fromParams(CreateAccountParams params) {
    final CityEntity? city = params.city;
    if (city == null) {
      throw ArgumentError.value(params.city, 'params.city', 'must not be null');
    }
    return CreateAccountRequestModel(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      teamName: params.teamName,
      cityId: city.id,
      timeZone: city.timeZone,
    );
  }

  static const String _timeZoneKey = 'timeZone';

  final String firstName;
  final String lastName;
  final String email;
  final String teamName;
  final String cityId;

  /// IANA id of the city's time zone.
  final String timeZone;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      AccountFields.firstName: firstName,
      AccountFields.lastName: lastName,
      AccountFields.email: email,
      AccountFields.teamName: teamName,
      AccountFields.city: cityId,
      _timeZoneKey: timeZone,
    };
  }
}
