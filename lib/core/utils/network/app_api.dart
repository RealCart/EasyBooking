/// Every API path, header, and hand-written request key used by the app.
///
/// Models do not use these keys: `json_serializable` takes a model's JSON
/// keys from its field names, so a field must be named exactly like its API
/// key.
abstract final class AppApi {
  /// Set with `--dart-define=API_BASE_URL=https://...`.
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  // Headers.
  static const String authorizationHeader = 'Authorization';
  static const String bearerScheme = 'Bearer';

  // Auth endpoints.
  static const String sendCode = '/auth/otp/send';
  static const String verifyCode = '/auth/otp/verify';
  static const String account = '/auth/account';

  // Auth request keys.
  static const String phoneKey = 'phone';
  static const String codeKey = 'code';

  // Account field keys, as reported in `errors` of a validation response.
  static const String firstNameKey = 'firstName';
  static const String lastNameKey = 'lastName';
  static const String emailKey = 'email';
  static const String teamNameKey = 'teamName';
  static const String cityKey = 'city';
}
