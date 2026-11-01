import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/core/utils/plural.dart';
import 'package:easy_booking/features/properties/domain/entity/property_availability_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/property_list_options.dart';
import 'package:easy_booking/features/properties/domain/entity/upcoming_stay_entity.dart';

extension PropertiesFilterLabels on PropertiesFilter {
  String get label {
    return switch (this) {
      PropertiesFilter.all => 'Все',
      PropertiesFilter.free => 'Свободны',
      PropertiesFilter.busy => 'Заняты',
    };
  }

  String get emptyTitle {
    return switch (this) {
      PropertiesFilter.all => 'Квартир пока нет',
      PropertiesFilter.free => 'Свободных квартир нет',
      PropertiesFilter.busy => 'Занятых квартир нет',
    };
  }
}

extension PropertySortLabels on PropertySort {
  String get label {
    return switch (this) {
      PropertySort.recommended => 'Сначала важные',
      PropertySort.priceLow => 'Сначала дешевле',
      PropertySort.priceHigh => 'Сначала дороже',
    };
  }
}

extension PropertyLabels on PropertyEntity {
  /// `Mega Towers · 126`
  String get shortTitle => '$name · $unit';

  /// `Esentai City · квартира 84`
  String get fullTitle => '$name · квартира $unit';

  /// `2 комнаты`
  String get roomsLabel {
    return Plural.format(
      rooms,
      one: 'комната',
      few: 'комнаты',
      many: 'комнат',
    );
  }

  /// `Аль-Фараби, 77/8 · 2 комнаты`
  String get addressWithRooms => '$address · $roomsLabel';

  /// `Алматы · Аль-Фараби, 77/8`
  String get cityAddress => '$city · $address';

  /// `2 комнаты · 54 м² · до 4 гостей`; the area is left out when unknown
  /// (`0`, as for a property added in the app).
  String get specs {
    final String guests = Plural.select(
      maxGuests,
      one: 'гостя',
      few: 'гостей',
      many: 'гостей',
    );
    return <String>[
      roomsLabel,
      if (areaSqm > 0) '$areaSqm м²',
      'до $maxGuests $guests',
    ].join(' · ');
  }

  /// `2 площадки · обновлено в 09:38`
  String get syncDetails {
    final String channels = Plural.format(
      channelNames.length,
      one: 'площадка',
      few: 'площадки',
      many: 'площадок',
    );
    return '$channels · обновлено в ${DateFormatter.time(syncedAt)}';
  }

  /// `42 500 ₸`
  String get price => MoneyFormatter.tenge(pricePerNight);

  /// `42 500 ₸ / ночь`
  String get pricePerNightLabel => MoneyFormatter.tengePerNight(pricePerNight);
}

extension PropertyAvailabilityLabels on PropertyAvailabilityEntity {
  /// `Заезд сегодня, 18:30`, `Свободна до 25 октября`; [short] uses short
  /// month names.
  String status({bool short = false}) {
    final DateTime? at = this.at;
    return switch (kind) {
      PropertyAvailabilityKind.checkInToday when at != null =>
        'Заезд сегодня, ${DateFormatter.time(at)}',
      PropertyAvailabilityKind.checkInToday => 'Заезд сегодня',
      PropertyAvailabilityKind.occupied when at != null =>
        'Занята до ${DateFormatter.dayMonth(at, short: short)}',
      PropertyAvailabilityKind.occupied => 'Занята',
      PropertyAvailabilityKind.freeUntil when at != null =>
        'Свободна до ${DateFormatter.dayMonth(at, short: short)}',
      PropertyAvailabilityKind.freeUntil ||
      PropertyAvailabilityKind.free => 'Свободна',
    };
  }

  /// The photo badge: `Заезд сегодня`, `Занята`, `Свободна`.
  String get badge {
    return switch (kind) {
      PropertyAvailabilityKind.checkInToday => 'Заезд сегодня',
      PropertyAvailabilityKind.occupied => 'Занята',
      PropertyAvailabilityKind.freeUntil ||
      PropertyAvailabilityKind.free => 'Свободна',
    };
  }
}

extension UpcomingStayLabels on UpcomingStayEntity {
  /// `22–25 окт · 3 ночи · 2 гостя`
  String get details {
    final String dates = DateFormatter.dayRange(checkIn, checkOut, short: true);
    final String nightsLabel = Plural.format(
      nights,
      one: 'ночь',
      few: 'ночи',
      many: 'ночей',
    );
    final String guests = Plural.format(
      guestCount,
      one: 'гость',
      few: 'гостя',
      many: 'гостей',
    );
    return '$dates · $nightsLabel · $guests';
  }
}
