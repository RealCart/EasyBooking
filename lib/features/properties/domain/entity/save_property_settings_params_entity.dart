import 'package:equatable/equatable.dart';

final class SavePropertySettingsParamsEntity extends Equatable {
  const SavePropertySettingsParamsEntity({
    required this.propertyId,
    required this.acceptsBookings,
  });

  final String propertyId;
  final bool acceptsBookings;

  @override
  List<Object?> get props => <Object?>[propertyId, acceptsBookings];
}
