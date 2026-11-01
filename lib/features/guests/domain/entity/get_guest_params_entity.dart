import 'package:equatable/equatable.dart';

final class GetGuestParamsEntity extends Equatable {
  const GetGuestParamsEntity({required this.guestId});

  final String guestId;

  @override
  List<Object?> get props => <Object?>[guestId];
}
