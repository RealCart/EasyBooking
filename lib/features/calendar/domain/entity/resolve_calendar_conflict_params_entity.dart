import 'package:equatable/equatable.dart';

final class ResolveCalendarConflictParamsEntity extends Equatable {
  const ResolveCalendarConflictParamsEntity({
    required this.conflictId,
    required this.keepBookingId,
  });

  final String conflictId;

  /// The booking to keep; the other one is cancelled in EasyBooking only.
  final String keepBookingId;

  @override
  List<Object?> get props => <Object?>[conflictId, keepBookingId];
}
