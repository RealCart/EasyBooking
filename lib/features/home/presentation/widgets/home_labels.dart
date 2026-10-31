import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/home/presentation/mock/home_mock_data.dart';

extension HomeStayScopeLabels on HomeStayScope {
  /// `Заезды`
  String get label {
    return switch (this) {
      HomeStayScope.arrivals => 'Заезды',
      HomeStayScope.departures => 'Выезды',
      HomeStayScope.staying => 'Проживают',
    };
  }

  /// `Сегодня заездов нет`
  String get emptyTitle {
    return switch (this) {
      HomeStayScope.arrivals => 'Сегодня заездов нет',
      HomeStayScope.departures => 'Сегодня выездов нет',
      HomeStayScope.staying => 'Сейчас никто не проживает',
    };
  }
}

extension HomeStayStatusLabels on HomeStayStatus {
  String get label {
    return switch (this) {
      HomeStayStatus.ready => 'К заезду всё готово',
      HomeStayStatus.awaitingContract => 'Ожидает договор',
      HomeStayStatus.cleaningScheduled => 'Уборка назначена',
      HomeStayStatus.contractSigned => 'Договор подписан',
    };
  }

  String get iconPath {
    return switch (this) {
      HomeStayStatus.awaitingContract => AppAssets.icons.documentTextSmall,
      HomeStayStatus.ready ||
      HomeStayStatus.cleaningScheduled ||
      HomeStayStatus.contractSigned => AppAssets.icons.checkSmall,
    };
  }
}

extension HomeStayLabels on HomeStayMock {
  /// `Айжан · 3 ночи`
  String get stayDetails {
    final String nightsLabel = Plural.format(
      nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );
    return '$guestName · $nightsLabel';
  }

  /// Check-in time for arrivals, check-out time for departures, and the
  /// check-out day (`до 25 окт`) for current guests.
  String badgeFor(HomeStayScope scope) {
    return switch (scope) {
      HomeStayScope.arrivals => DateFormatter.time(checkIn),
      HomeStayScope.departures => DateFormatter.time(checkOut),
      HomeStayScope.staying =>
        'до ${DateFormatter.dayMonth(checkOut, short: true)}',
    };
  }
}

extension HomeSyncLabels on HomeSyncMock {
  /// `Календари обновлены в 09:38`
  String get title => 'Календари обновлены в ${DateFormatter.time(updatedAt)}';

  /// `Booking.com и Airbnb · 4 объекта`
  String get subtitle {
    final String channels = channelNames.length < 2
        ? channelNames.join()
        : '${channelNames.sublist(0, channelNames.length - 1).join(', ')} '
              'и ${channelNames.last}';
    final String properties = Plural.format(
      propertyCount,
      one: 'объект',
      few: 'объекта',
      many: 'объектов',
    );
    return '$channels · $properties';
  }
}
