import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';

extension SupportContactLabels on SupportContactEntity {
  /// `Обычно отвечаем за 10 минут`
  String get responseTimeLabel {
    final int minutes = typicalResponseTime.inMinutes;
    if (minutes >= Duration.minutesPerHour) {
      final int hours = typicalResponseTime.inHours;
      return 'Обычно отвечаем за '
          '${Plural.format(hours, one: 'час', few: 'часа', many: 'часов')}';
    }
    return 'Обычно отвечаем за '
        '${Plural.format(minutes, one: 'минуту', few: 'минуты', many: 'минут')}';
  }
}

extension HelpGuideLabels on HelpGuideEntity {
  /// `4 минуты`
  String get readingTimeLabel {
    return Plural.format(
      readingTime.inMinutes,
      one: 'минута',
      few: 'минуты',
      many: 'минут',
    );
  }
}
