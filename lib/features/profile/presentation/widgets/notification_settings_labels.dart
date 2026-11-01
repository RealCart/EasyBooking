import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';

/// A titled group of topics on «Настройки уведомлений».
typedef NotificationTopicGroup = ({
  String title,
  List<NotificationTopic> topics,
});

/// The groups of the screen, in display order.
const List<NotificationTopicGroup> notificationTopicGroups =
    <NotificationTopicGroup>[
      (
        title: 'Операции',
        topics: <NotificationTopic>[
          NotificationTopic.newBooking,
          NotificationTopic.checkInOut,
          NotificationTopic.priceChange,
        ],
      ),
      (
        title: 'Договоры',
        topics: <NotificationTopic>[
          NotificationTopic.contractAwaitingSignature,
          NotificationTopic.contractSigned,
        ],
      ),
      (
        title: 'Синхронизация',
        topics: <NotificationTopic>[
          NotificationTopic.channelError,
          NotificationTopic.syncSuccess,
        ],
      ),
    ];

extension NotificationTopicLabels on NotificationTopic {
  String get title {
    return switch (this) {
      NotificationTopic.newBooking => 'Новая бронь',
      NotificationTopic.checkInOut => 'Заезд и выезд',
      NotificationTopic.priceChange => 'Изменение цены',
      NotificationTopic.contractAwaitingSignature => 'Ожидает подписи',
      NotificationTopic.contractSigned => 'Договор подписан',
      NotificationTopic.channelError => 'Ошибка канала',
      NotificationTopic.syncSuccess => 'Успешное обновление',
    };
  }

  /// When and how the notification arrives.
  String get hint {
    return switch (this) {
      NotificationTopic.newBooking => 'Пуш сразу после подтверждения',
      NotificationTopic.checkInOut => 'Напоминание за 2 часа',
      NotificationTopic.priceChange => 'Только изменения от площадок',
      NotificationTopic.contractAwaitingSignature =>
        'Через 1 час после открытия',
      NotificationTopic.contractSigned => 'Пуш и письмо владельцу',
      NotificationTopic.channelError => 'Всегда, без тихого режима',
      NotificationTopic.syncSuccess => 'Сводка один раз в день',
    };
  }
}

extension NotificationDeliveryChannelLabels on NotificationDeliveryChannel {
  String get label {
    return switch (this) {
      NotificationDeliveryChannel.push => 'Push',
      NotificationDeliveryChannel.email => 'Email',
      NotificationDeliveryChannel.sms => 'SMS важное',
    };
  }
}
