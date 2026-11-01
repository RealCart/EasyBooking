import 'package:equatable/equatable.dart';

enum GuestDocumentKind {
  /// «Удостоверение личности».
  idCard,

  /// «Паспорт».
  passport,
}

enum GuestDocumentStatus {
  /// Uploaded, not checked yet.
  pending,

  /// Checked by the host («Проверено»).
  verified,
}

/// The identity document a guest uploaded.
final class GuestDocumentEntity extends Equatable {
  const GuestDocumentEntity({
    required this.kind,
    required this.status,
    required this.updatedAt,
  });

  final GuestDocumentKind kind;
  final GuestDocumentStatus status;

  /// When [status] was reached: uploaded or verified.
  final DateTime updatedAt;

  @override
  List<Object?> get props => <Object?>[kind, status, updatedAt];
}
