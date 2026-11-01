import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';

import '../../../../helpers/fake_contracts_repository.dart';

void main() {
  group('ContractTimeLabels.reminder', () {
    String? reminderIn(Duration left) {
      return ContractTimeLabels.reminder(
        remindAt: contractsTestNow.add(left),
        now: contractsTestNow,
      );
    }

    test('no reminder is null', () {
      expect(
        ContractTimeLabels.reminder(remindAt: null, now: contractsTestNow),
        isNull,
      );
    });

    test('rounds to minutes under an hour and to hours above', () {
      expect(
        reminderIn(const Duration(seconds: 30)),
        'Напоминание отправляется',
      );
      expect(
        reminderIn(const Duration(minutes: -5)),
        'Напоминание отправляется',
      );
      expect(
        reminderIn(const Duration(minutes: 1)),
        'Напомнить через 1 минуту',
      );
      expect(
        reminderIn(const Duration(minutes: 45)),
        'Напомнить через 45 минут',
      );
      expect(reminderIn(const Duration(hours: 1)), 'Напомнить через 1 час');
      expect(reminderIn(const Duration(hours: 2)), 'Напомнить через 2 часа');
      expect(
        reminderIn(const Duration(hours: 4, minutes: 40)),
        'Напомнить через 5 часов',
      );
    });
  });

  group('ContractMask', () {
    test('phone masks the middle of a Kazakhstan number', () {
      expect(ContractMask.phone('+77003184521'), '+7 700 ••• 45 21');
      expect(ContractMask.phone('guest@mail.kz'), 'guest@mail.kz');
    });

    test('tail keeps the last characters and the spaces', () {
      expect(ContractMask.tail('048216721', visibleTail: 4), '•••••6721');
      expect(ContractMask.tail('12 34', visibleTail: 2), '•• 34');
      expect(ContractMask.tail('12', visibleTail: 3), '12');
    });
  });

  group('contract failure texts', () {
    test('known codes get their own message, others the shared one', () {
      expect(
        const ValidationFailure(
          code: ContractErrorCodes.alreadySigned,
        ).contractMessage,
        'Договор уже подписан, изменить его нельзя',
      );
      expect(
        const ValidationFailure(
          code: ContractErrorCodes.invalidPhone,
        ).contractMessage,
        FormValidators.invalidPhoneMessage,
      );
      expect(
        const ValidationFailure(
          code: ContractErrorCodes.invalidEmail,
        ).contractMessage,
        FormValidators.invalidEmailMessage,
      );
      expect(
        const ConnectionFailure().contractMessage,
        'Нет подключения к интернету',
      );
    });

    test('only a 404 means the contract is missing', () {
      expect(const ServerFailure(statusCode: 404).isContractMissing, isTrue);
      expect(const ServerFailure(statusCode: 500).isContractMissing, isFalse);
      expect(const ConnectionFailure().isContractMissing, isFalse);
    });

    test('field codes map to the form messages', () {
      expect(contractFieldErrorMessage(null), isNull);
      expect(contractFieldErrorMessage(''), isNull);
      expect(
        contractFieldErrorMessage(ContractErrorCodes.required),
        FormValidators.requiredMessage,
      );
      expect(
        contractFieldErrorMessage(ContractErrorCodes.invalidIin),
        FormValidators.invalidIinMessage,
      );
      expect(
        contractFieldErrorMessage(ContractErrorCodes.invalidIdNumber),
        FormValidators.invalidIdNumberMessage,
      );
      expect(contractFieldErrorMessage('other'), 'Проверьте поле');
    });
  });
}
