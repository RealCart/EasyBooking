import 'package:json_annotation/json_annotation.dart';

part 'error_response_model.g.dart';

/// Error payload `{code, message, errors}` of a failed response.
///
/// Read leniently: a value of an unexpected type is dropped instead of
/// failing, so a malformed error body never hides the HTTP status. `errors`
/// may map a field to a string or to a list of strings; only the first
/// string is kept.
@JsonSerializable(createToJson: false)
final class ErrorResponseModel {
  const ErrorResponseModel({
    this.code,
    this.message,
    this.errors = const <String, String>{},
  });

  factory ErrorResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseModelFromJson(json);

  /// Parses any response body; a non-object body gives an empty model.
  factory ErrorResponseModel.parse(Object? data) {
    if (data is! Map<String, Object?>) {
      return const ErrorResponseModel();
    }
    return ErrorResponseModel.fromJson(data);
  }

  @JsonKey(fromJson: _stringOrNull)
  final String? code;

  @JsonKey(fromJson: _stringOrNull)
  final String? message;

  /// Field name to the first error text for that field.
  @JsonKey(fromJson: _fieldErrors)
  final Map<String, String> errors;
}

String? _stringOrNull(Object? value) => value is String ? value : null;

Map<String, String> _fieldErrors(Object? errors) {
  if (errors is! Map<String, Object?>) {
    return const <String, String>{};
  }
  final Map<String, String> result = <String, String>{};
  for (final MapEntry<String, Object?>(:String key, :Object? value)
      in errors.entries) {
    final String? text = switch (value) {
      final String text => text,
      [final String first, ...] => first,
      _ => null,
    };
    if (text != null) {
      result[key] = text;
    }
  }
  return Map<String, String>.unmodifiable(result);
}
