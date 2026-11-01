import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/profile/domain/entity/notification_settings_entity.dart';

/// Input of `UpdateNotificationSettingsUsecase`: every toggle and channel
/// of the screen, saved together by «Сохранить настройки».
final class UpdateNotificationSettingsParamsEntity extends Equatable {
  const UpdateNotificationSettingsParamsEntity({
    required this.enabledTopics,
    required this.channels,
  });

  final Set<NotificationTopic> enabledTopics;

  /// Must not be empty.
  final Set<NotificationDeliveryChannel> channels;

  @override
  List<Object?> get props => <Object?>[enabledTopics, channels];
}
