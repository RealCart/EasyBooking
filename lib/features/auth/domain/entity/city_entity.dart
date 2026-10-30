import 'package:equatable/equatable.dart';

final class CityEntity extends Equatable {
  const CityEntity({
    required this.id,
    required this.name,
    required this.timeZone,
    required this.utcOffset,
  });

  /// Lowercase Latin slug sent to the server, for example `almaty`.
  final String id;

  final String name;

  /// IANA time zone id, for example `Asia/Almaty`.
  final String timeZone;

  final Duration utcOffset;

  @override
  List<Object?> get props => <Object?>[id, name, timeZone, utcOffset];
}
