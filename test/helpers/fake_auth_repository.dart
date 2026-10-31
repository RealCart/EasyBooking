import 'dart:async';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/create_account_params_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';

const Either<Failure, void> voidSuccess = Right<Failure, void>(null);

/// [AuthRepository] that records every call and answers with the configured
/// results.
///
/// Set a `hold*` flag to keep the next calls of that method pending; each
/// pending call gets a completer in the matching `held*` list, which the
/// test completes in any order.
final class FakeAuthRepository implements AuthRepository {
  /// `null` answers with an [OtpChallengeEntity] for the requested phone and
  /// [resendAfter].
  Either<Failure, OtpChallengeEntity>? sendCodeResult;
  Duration resendAfter = const Duration(seconds: 30);
  Either<Failure, void> verifyCodeResult = voidSuccess;
  Either<Failure, void> createAccountResult = voidSuccess;
  Either<Failure, void> signOutResult = voidSuccess;

  bool holdSendCode = false;
  bool holdVerifyCode = false;
  bool holdCreateAccount = false;
  bool holdSignOut = false;

  final List<Completer<Either<Failure, OtpChallengeEntity>>> heldSendCodes =
      <Completer<Either<Failure, OtpChallengeEntity>>>[];
  final List<Completer<Either<Failure, void>>> heldVerifyCodes =
      <Completer<Either<Failure, void>>>[];
  final List<Completer<Either<Failure, void>>> heldCreateAccounts =
      <Completer<Either<Failure, void>>>[];
  final List<Completer<Either<Failure, void>>> heldSignOuts =
      <Completer<Either<Failure, void>>>[];

  final List<String> sentPhones = <String>[];
  final List<({String phone, String code})> verifyCalls =
      <({String phone, String code})>[];
  final List<CreateAccountParamsEntity> createAccountCalls =
      <CreateAccountParamsEntity>[];
  int signOutCount = 0;

  /// The success answer [sendCode] gives for [phone] by default.
  OtpChallengeEntity challengeFor(String phone) {
    return OtpChallengeEntity(phone: phone, resendAfter: resendAfter);
  }

  @override
  Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone) {
    sentPhones.add(phone);
    return _answer(
      hold: holdSendCode,
      held: heldSendCodes,
      result:
          sendCodeResult ??
          Right<Failure, OtpChallengeEntity>(challengeFor(phone)),
    );
  }

  @override
  Future<Either<Failure, void>> verifyCode({
    required String phone,
    required String code,
  }) {
    verifyCalls.add((phone: phone, code: code));
    return _answer(
      hold: holdVerifyCode,
      held: heldVerifyCodes,
      result: verifyCodeResult,
    );
  }

  @override
  Future<Either<Failure, void>> createAccount(
    CreateAccountParamsEntity params,
  ) {
    createAccountCalls.add(params);
    return _answer(
      hold: holdCreateAccount,
      held: heldCreateAccounts,
      result: createAccountResult,
    );
  }

  @override
  Future<Either<Failure, void>> signOut() {
    signOutCount++;
    return _answer(
      hold: holdSignOut,
      held: heldSignOuts,
      result: signOutResult,
    );
  }

  static Future<T> _answer<T>({
    required bool hold,
    required List<Completer<T>> held,
    required T result,
  }) {
    if (!hold) {
      return Future<T>.value(result);
    }
    final Completer<T> completer = Completer<T>();
    held.add(completer);
    return completer.future;
  }
}
