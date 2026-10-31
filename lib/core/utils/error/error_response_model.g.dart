// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponseModel _$ErrorResponseModelFromJson(Map<String, dynamic> json) =>
    ErrorResponseModel(
      code: _stringOrNull(json['code']),
      message: _stringOrNull(json['message']),
      errors: json['errors'] == null
          ? const <String, String>{}
          : _fieldErrors(json['errors']),
    );
