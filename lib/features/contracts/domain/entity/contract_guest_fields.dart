import 'package:easy_booking/core/utils/network/app_api.dart';

/// Guest form field keys, used in `ValidationFailure.fieldErrors`.
abstract final class ContractGuestFields {
  static const String firstName = AppApi.firstNameKey;
  static const String lastName = AppApi.lastNameKey;

  // The contracts API does not exist yet; move these keys to `AppApi` with
  // its endpoints.
  static const String patronymic = 'patronymic';
  static const String iin = 'iin';
  static const String idNumber = 'idNumber';
}
