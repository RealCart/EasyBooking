import 'package:equatable/equatable.dart';

import 'package:easy_booking/features/properties/domain/entity/booking_channel.dart';

/// Step 2 of «Добавить квартиру». An empty list is allowed: channels can be
/// connected later.
final class SaveAddPropertyChannelsParamsEntity extends Equatable {
  const SaveAddPropertyChannelsParamsEntity({required this.channels});

  final List<BookingChannel> channels;

  @override
  List<Object?> get props => <Object?>[channels];
}
