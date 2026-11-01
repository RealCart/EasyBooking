import 'package:equatable/equatable.dart';

enum SecurityEventKind {
  /// «Успешный вход».
  signedIn,

  /// «Код приложения изменён».
  appCodeChanged,

  /// «Другие сеансы завершены».
  otherSessionsTerminated,
}

/// One row of «Последние действия».
final class SecurityEventEntity extends Equatable {
  const SecurityEventEntity({
    required this.id,
    required this.kind,
    required this.occurredAt,
    this.deviceName,
  });

  final String id;
  final SecurityEventKind kind;
  final DateTime occurredAt;

  /// The device that caused the event, such as `iPhone`, when known.
  final String? deviceName;

  @override
  List<Object?> get props => <Object?>[id, kind, occurredAt, deviceName];
}
