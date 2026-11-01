import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_connection_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channel_entity.dart';
import 'package:easy_booking/features/calendar/domain/entity/channels_overview_entity.dart';
import 'package:easy_booking/features/calendar/presentation/widgets/calendar_labels.dart';

extension ChannelLabels on ChannelEntity {
  /// `A` for Airbnb: the letter on the channel's logo tile.
  String get initial {
    final String name = this.name.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  /// `Подключён`, `Ошибка`, `Отключён`; `null` for a manual channel, which
  /// shows «Настроить» instead.
  String? get statusLabel {
    return switch (status) {
      ChannelStatus.connected => 'Подключён',
      ChannelStatus.failed => 'Ошибка',
      ChannelStatus.disconnected => 'Отключён',
      ChannelStatus.manual => null,
    };
  }

  /// The second line on «Каналы»: `3 объекта · обновлено 09:38`,
  /// `4 объекта · один требует внимания`, or the mode of a channel without
  /// an import.
  String listSubtitle({required DateTime now}) {
    final String count = CalendarLabels.properties(propertyCount);
    final DateTime? syncedAt = lastSyncedAt;
    return switch (status) {
      ChannelStatus.connected =>
        syncedAt == null
            ? count
            : '$count · обновлено ${CalendarLabels.checkTime(syncedAt, now: now)}',
      ChannelStatus.failed =>
        '$count · ${_attention(failedConnections.length)}',
      ChannelStatus.manual => 'Ручные брони · экспорт iCal',
      ChannelStatus.disconnected => 'Календарь не синхронизируется',
    };
  }

  /// Under the name on «Канал»: `Подключён · 4 объекта`.
  String get detailSubtitle {
    final String count = CalendarLabels.properties(propertyCount);
    return switch (status) {
      ChannelStatus.connected => 'Подключён · $count',
      ChannelStatus.failed => 'Ошибка · $count',
      ChannelStatus.manual => 'Ручные брони · экспорт iCal',
      ChannelStatus.disconnected => 'Отключён',
    };
  }

  /// `Последняя успешная синхронизация сегодня в 09:38.`
  String lastSyncLabel({required DateTime now}) {
    final DateTime? syncedAt = lastSyncedAt;
    if (syncedAt == null) {
      return status == ChannelStatus.manual
          ? 'Брони вносятся вручную, EasyBooking только отдаёт свой календарь.'
          : 'Успешных синхронизаций ещё не было.';
    }
    return 'Последняя успешная синхронизация '
        '${CalendarLabels.dayAtTime(syncedAt, now: now)}.';
  }

  /// `EasyBooking проверяет ссылку каждые 15 минут.`
  String get checkIntervalLabel {
    final int minutes = checkInterval.inMinutes;
    final String every = Plural.select(
      minutes,
      one: 'каждую',
      few: 'каждые',
      many: 'каждые',
    );
    return 'EasyBooking проверяет ссылку $every ${_minutes(minutes)}.';
  }

  /// `Следующая автоматическая проверка через 8 минут.`; `null` when
  /// nothing is checked automatically.
  String? nextCheckLabel({required DateTime now}) {
    final DateTime? nextCheckAt = this.nextCheckAt;
    if (nextCheckAt == null) {
      return null;
    }
    final int minutes = nextCheckAt.difference(now).inMinutes;
    if (minutes < 1) {
      return 'Следующая автоматическая проверка меньше чем через минуту.';
    }
    return 'Следующая автоматическая проверка через ${_minutes(minutes)}.';
  }

  /// `Airbnb не обновился`
  String get failureTitle => '$name не обновился';

  /// `Esentai City · проверьте ссылку iCal`
  String get failureMessage {
    final String properties = failedConnections
        .map((ChannelConnectionEntity connection) => connection.propertyName)
        .toSet()
        .join(', ');
    return '$properties · проверьте ссылку iCal';
  }

  static String _attention(int count) {
    if (count == 1) {
      return 'один требует внимания';
    }
    final String verb = Plural.select(
      count,
      one: 'требует',
      few: 'требуют',
      many: 'требуют',
    );
    return '$count $verb внимания';
  }

  static String _minutes(int count) {
    return Plural.format(count, one: 'минуту', few: 'минуты', many: 'минут');
  }
}

extension ChannelsOverviewLabels on ChannelsOverviewEntity {
  /// `3 подключения · 4 объекта`
  String get summary {
    final String connections = Plural.format(
      activeChannelCount,
      one: 'подключение',
      few: 'подключения',
      many: 'подключений',
    );
    return '$connections · ${CalendarLabels.properties(propertyCount)}';
  }

  /// `Последняя проверка 09:38`
  String checkedLabel({required DateTime now}) {
    return 'Последняя проверка ${CalendarLabels.checkTime(checkedAt, now: now)}';
  }
}

extension ChannelConnectionLabels on ChannelConnectionEntity {
  /// `Esentai City · 84`
  String get title => '$propertyName · $unit';

  /// `Импорт и экспорт` or `Только импорт`.
  String get modeLabel {
    return switch (mode) {
      ChannelSyncMode.importAndExport => 'Импорт и экспорт',
      ChannelSyncMode.importOnly => 'Только импорт',
    };
  }

  /// `Работает` or `Проверить`.
  String get statusLabel {
    return switch (status) {
      ChannelConnectionStatus.working => 'Работает',
      ChannelConnectionStatus.failed => 'Проверить',
    };
  }
}
