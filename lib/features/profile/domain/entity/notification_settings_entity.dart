import 'package:equatable/equatable.dart';

/// Events the user can be notified about, grouped on the screen as
/// «Операции», «Договоры» and «Синхронизация».
enum NotificationTopic {
  newBooking,
  checkInOut,
  priceChange,
  contractAwaitingSignature,
  contractSigned,
  channelError,
  syncSuccess,
}

enum NotificationDeliveryChannel {
  push,
  email,

  /// SMS, for important events only.
  sms,
}

/// Saved settings of «Настройки уведомлений».
final class NotificationSettingsEntity extends Equatable {
  const NotificationSettingsEntity({
    required this.enabledTopics,
    required this.channels,
  });

  /// Topics that are switched on; the others are off.
  final Set<NotificationTopic> enabledTopics;

  /// Selected delivery channels; never empty.
  final Set<NotificationDeliveryChannel> channels;

  bool isEnabled(NotificationTopic topic) => enabledTopics.contains(topic);

  @override
  List<Object?> get props => <Object?>[enabledTopics, channels];
}
