import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';

import '../../../../helpers/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late SendCodeUsecase usecase;

  setUp(() {
    repository = FakeAuthRepository();
    usecase = SendCodeUsecase(repository);
  });

  group('SendCodeUsecase', () {
    test('normalizes any typed format to E.164 before sending', () async {
      for (final String input in <String>[
        '7001234567',
        '700 123 45 67',
        '+7 (700) 123-45-67',
        '87001234567',
        '77001234567',
      ]) {
        repository.sentPhones.clear();

        await usecase(input);

        expect(repository.sentPhones, <String>['+77001234567'], reason: input);
      }
    });

    test('returns the repository challenge on success', () async {
      final Either<Failure, OtpChallengeEntity> result = await usecase(
        '7001234567',
      );

      expect(
        result,
        const Right<Failure, OtpChallengeEntity>(
          OtpChallengeEntity(
            phone: '+77001234567',
            resendAfter: Duration(seconds: 30),
          ),
        ),
      );
    });

    test('preserves a repository failure', () async {
      const Failure failure = ServerFailure(
        statusCode: 429,
        code: AuthErrorCodes.tooManyRequests,
      );
      repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
        failure,
      );

      expect(
        await usecase('7001234567'),
        const Left<Failure, OtpChallengeEntity>(failure),
      );
    });

    test('rejects an invalid phone without calling the repository', () async {
      for (final String input in <String>[
        '',
        '700123456',
        '6001234567',
        '700123456789',
        'phone',
      ]) {
        expect(
          await usecase(input),
          const Left<Failure, OtpChallengeEntity>(
            ValidationFailure(code: AuthErrorCodes.invalidPhone),
          ),
          reason: input,
        );
      }
      expect(repository.sentPhones, isEmpty);
    });
  });
}
