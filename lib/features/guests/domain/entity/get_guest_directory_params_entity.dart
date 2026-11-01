import 'package:equatable/equatable.dart';

final class GetGuestDirectoryParamsEntity extends Equatable {
  const GetGuestDirectoryParamsEntity({this.query = ''});

  /// Name, phone, property, or contract number; empty for recent guests.
  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}
