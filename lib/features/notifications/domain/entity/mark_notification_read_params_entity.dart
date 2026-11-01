import 'package:equatable/equatable.dart';

final class MarkNotificationReadParamsEntity extends Equatable {
  const MarkNotificationReadParamsEntity({required this.id});

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}
