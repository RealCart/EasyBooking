import 'package:easy_booking/core/utils/network/app_api.dart';

/// Profile and team form field keys, used in
/// `ValidationFailure.fieldErrors` by the use cases and the server, which
/// reports errors under the request keys.
abstract final class ProfileFields {
  static const String firstName = AppApi.firstNameKey;
  static const String lastName = AppApi.lastNameKey;
  static const String email = AppApi.emailKey;
  static const String teamName = AppApi.teamNameKey;
  static const String city = AppApi.cityKey;
  static const String phone = AppApi.phoneKey;
}
