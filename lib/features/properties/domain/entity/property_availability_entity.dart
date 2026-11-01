import 'package:equatable/equatable.dart';

enum PropertyAvailabilityKind {
  /// A guest checks in today at [PropertyAvailabilityEntity.at].
  checkInToday,

  /// A guest stays until [PropertyAvailabilityEntity.at].
  occupied,

  /// Free until the next check-in at [PropertyAvailabilityEntity.at].
  freeUntil,

  /// Free with no upcoming booking; [PropertyAvailabilityEntity.at] is
  /// `null`.
  free,
}

/// Where a property stands today, as computed by the source.
final class PropertyAvailabilityEntity extends Equatable {
  const PropertyAvailabilityEntity({required this.kind, this.at});

  final PropertyAvailabilityKind kind;
  final DateTime? at;

  /// Has a guest today: staying or arriving.
  bool get isBusy {
    return kind == PropertyAvailabilityKind.checkInToday ||
        kind == PropertyAvailabilityKind.occupied;
  }

  @override
  List<Object?> get props => <Object?>[kind, at];
}
