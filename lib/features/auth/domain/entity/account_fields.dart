import 'package:easy_booking/core/utils/network/app_api.dart';

/// Account field keys, used in `ValidationFailure.fieldErrors` by both the
/// use case and the server, which reports errors under the request keys.
abstract final class AccountFields {
  static const String firstName = AppApi.firstNameKey;
  static const String lastName = AppApi.lastNameKey;
  static const String email = AppApi.emailKey;
  static const String teamName = AppApi.teamNameKey;
  static const String city = AppApi.cityKey;
}
