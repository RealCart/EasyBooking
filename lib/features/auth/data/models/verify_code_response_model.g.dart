// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_code_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyCodeResponseModel _$VerifyCodeResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('VerifyCodeResponseModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['accessToken', 'isNewUser']);
  final val = VerifyCodeResponseModel(
    accessToken: $checkedConvert('accessToken', (v) => _nonEmptyString(v)),
    isNewUser: $checkedConvert('isNewUser', (v) => v as bool),
    refreshToken: $checkedConvert('refreshToken', (v) => v as String?),
  );
  return val;
});
