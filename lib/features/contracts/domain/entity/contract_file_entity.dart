import 'package:equatable/equatable.dart';

/// A file attached to a contract: the contract itself or the guest's
/// identity document.
final class ContractFileEntity extends Equatable {
  const ContractFileEntity({
    required this.name,
    required this.pageCount,
    required this.sizeBytes,
    this.language,
  });

  /// As shown to the user: «Договор найма», «Удостоверение.pdf».
  final String name;
  final int pageCount;
  final int sizeBytes;

  /// The document language as shown: «русский язык»; `null` when unknown.
  final String? language;

  @override
  List<Object?> get props => <Object?>[name, pageCount, sizeBytes, language];
}
