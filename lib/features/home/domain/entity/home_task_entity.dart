import 'package:equatable/equatable.dart';

enum HomeTaskKind {
  /// A contract the guest still has to sign; [HomeTaskEntity.targetId] is
  /// the contract id.
  contract,

  /// Preparing a property for an arrival; [HomeTaskEntity.targetId] is the
  /// property id.
  preparation,
}

/// An open task before today's arrivals.
final class HomeTaskEntity extends Equatable {
  const HomeTaskEntity({
    required this.kind,
    required this.targetId,
    required this.title,
    required this.subtitle,
    this.dueAt,
  });

  final HomeTaskKind kind;
  final String targetId;
  final String title;
  final String subtitle;

  /// Deadline of the task; `null` when it has none.
  final DateTime? dueAt;

  @override
  List<Object?> get props => <Object?>[kind, targetId, title, subtitle, dueAt];
}
