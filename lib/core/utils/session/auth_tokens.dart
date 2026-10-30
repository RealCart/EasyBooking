import 'package:equatable/equatable.dart';

final class AuthTokens extends Equatable {
  const AuthTokens({required this.accessToken, this.refreshToken});

  final String accessToken;
  final String? refreshToken;

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken];

  // Keeps tokens out of logs and error reports.
  @override
  String toString() => 'AuthTokens(<redacted>)';
}
