import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';

import '../../../../helpers/fake_auth_repository.dart';

const String _phone = '+77001234567';

void main() {
  late FakeAuthRepository repository;
  late VerifyCodeUsecase usecase;

  setUp(() {
    repository = FakeAuthRepository();
    usecase = VerifyCodeUsecase(repository);
  });

  group('VerifyCodeUsecase', () {
    test('forwards the phone and a six-digit code', () async {
      final Either<Failure, void> result = await usecase(
        const VerifyCodeParams(phone: _phone, code: '482913'),
      );

      expect(result.isRight, isTrue);
      expect(repository.verifyCalls, <({String phone, String code})>[
        (phone: _phone, code: '482913'),
      ]);
    });

    test('preserves a repository failure', () async {
      const Failure failure = ValidationFailure(
        code: AuthErrorCodes.codeExpired,
      );
      repository.verifyCodeResult = const Left<Failure, void>(failure);

      expect(
        await usecase(const VerifyCodeParams(phone: _phone, code: '482913')),
        const Left<Failure, void>(failure),
      );
    });

    test('returns invalid_code early for a malformed code', () async {
      for (final String code in <String>[
        '',
        '12345',
        '1234567',
        '12345a',
        '123 45',
        '١٢٣٤٥٦',
      ]) {
        expect(
          await usecase(VerifyCodeParams(phone: _phone, code: code)),
          const Left<Failure, void>(
            ValidationFailure(code: AuthErrorCodes.invalidCode),
          ),
          reason: code,
        );
      }
      expect(repository.verifyCalls, isEmpty);
    });

    test('params compare by phone and code', () {
      expect(
        const VerifyCodeParams(phone: _phone, code: '111111'),
        const VerifyCodeParams(phone: _phone, code: '111111'),
      );
      expect(
        const VerifyCodeParams(phone: _phone, code: '111111'),
        isNot(const VerifyCodeParams(phone: _phone, code: '222222')),
      );
    });
  });
}
