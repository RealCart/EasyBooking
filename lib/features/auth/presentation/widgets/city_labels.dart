import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';

extension CityLabels on CityEntity {
  /// `UTC+5`, or `UTC+5:30` for an offset with minutes.
  String get utcOffsetLabel {
    final int totalMinutes = utcOffset.inMinutes;
    final String sign = totalMinutes < 0 ? '-' : '+';
    final int hours = totalMinutes.abs() ~/ Duration.minutesPerHour;
    final int minutes = totalMinutes.abs() % Duration.minutesPerHour;
    final String suffix = minutes == 0
        ? ''
        : ':${minutes.toString().padLeft(2, '0')}';
    return 'UTC$sign$hours$suffix';
  }

  /// `Алматы · UTC+5`
  String get nameWithOffset => '$name · $utcOffsetLabel';
}
