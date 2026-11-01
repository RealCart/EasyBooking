import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_send_bloc/contract_send_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_send_screen.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_recipient_sheet.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_stay_card.dart';

import '../../../../helpers/fake_contracts_repository.dart';

/// [ContractSendScreen] for `c1` at `/contracts/c1/send` in a small GoRouter
/// whose other routes only show their location.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.bloc);

  final WidgetTester tester;
  final GoRouter router;
  final FakeContractsRepository repository;
  final ContractSendBloc bloc;

  static Future<_Harness> pump(
    WidgetTester tester, {
    void Function(FakeContractsRepository repository)? arrange,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeContractsRepository repository = FakeContractsRepository();
    arrange?.call(repository);
    final ContractSendBloc bloc = ContractSendBloc(
      getContract: GetContractUsecase(repository),
      sendContract: SendContractUsecase(repository),
    );
    Widget placeholder(BuildContext _, GoRouterState state) {
      return Scaffold(body: Text('Route ${state.uri}'));
    }

    final GoRouter router = GoRouter(
      initialLocation: '/contracts/c1/send',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.booking.name,
          path: AppRoutes.booking.path,
          builder: placeholder,
        ),
        GoRoute(
          name: AppRoutes.contract.name,
          path: AppRoutes.contract.path,
          builder: placeholder,
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.contractSend.name,
              path: AppRoutes.contractSend.path,
              builder: (_, GoRouterState state) {
                final String id =
                    state.pathParameters[AppRoutes.contractIdParam]!;
                return BlocProvider<ContractSendBloc>(
                  create: (_) => bloc..add(ContractSendRequested(id)),
                  child: ContractSendScreen(contractId: id),
                );
              },
            ),
            GoRoute(
              name: AppRoutes.contractStatus.name,
              path: AppRoutes.contractStatus.path,
              builder: placeholder,
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return _Harness(tester, router, repository, bloc);
  }

  String get location => router.state.uri.toString();

  Finder get sheet => find.byType(ContractRecipientSheet);

  Finder get sheetInput {
    return find.descendant(of: sheet, matching: find.byType(EditableText));
  }

  String get sheetText =>
      tester.widget<EditableText>(sheetInput).controller.text;

  Future<void> openSheet() async {
    await tester.tap(find.text('Изменить'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseChannel(String label) async {
    await tester.tap(find.descendant(of: sheet, matching: find.text(label)));
    await tester.pump();
  }

  Future<void> typeAddress(String text) async {
    await tester.enterText(sheetInput, text);
    await tester.pump();
  }

  Future<void> confirmSheet() async {
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();
  }

  Future<void> send() async {
    await tester.tap(find.text('Отправить на подпись'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('ContractSendScreen', () {
    testWidgets('shows the skeleton while the contract loads', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.holdGet = true,
        settle: false,
      );

      expect(find.byType(ContractSkeleton), findsOneWidget);
      expect(find.text('Отправить на подпись'), findsNothing);
    });

    testWidgets('an unknown contract says it was not found, without retry', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.getResult = const Left<Failure, ContractEntity>(
              ServerFailure(statusCode: 404),
            ),
      );

      expect(find.text('Договор не найден'), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);
    });

    testWidgets('a failed load offers a retry', (WidgetTester tester) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.getResult = const Left<Failure, ContractEntity>(
              TimeoutFailure(),
            ),
      );
      expect(find.text('Не удалось загрузить договор'), findsOneWidget);

      harness.repository.getResult = Right<Failure, ContractEntity>(
        testContract(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(harness.repository.getCalls, <String>['c1', 'c1']);
      expect(find.text('Условия и подпись'), findsOneWidget);
    });

    testWidgets('shows the terms, the stay, and the recipient', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(tester);

      expect(find.text('Условия и подпись'), findsOneWidget);
      expect(find.text('Договор № EB-1053 · черновик'), findsOneWidget);
      expect(find.text('Samal Residence · 12'), findsOneWidget);
      expect(find.text('22–24 октября · 2 ночи'), findsOneWidget);
      expect(
        find.text('Аренда · ${MoneyFormatter.tenge(38000)} × 2 ночи'),
        findsOneWidget,
      );
      expect(find.text(MoneyFormatter.tenge(76000)), findsOneWidget);
      expect(find.text(MoneyFormatter.tenge(50000)), findsOneWidget);
      expect(find.text('18:30 / 12:00'), findsOneWidget);
      expect(find.text('Договор найма'), findsOneWidget);
      expect(find.text('Данияр · +7 700 ••• 45 21'), findsOneWidget);
      expect(find.text('Ссылка на договор в SMS'), findsOneWidget);
    });

    testWidgets('the stay card opens the booking', (WidgetTester tester) async {
      final _Harness harness = await _Harness.pump(tester);

      await tester.tap(find.byType(ContractStayCard));
      await tester.pumpAndSettle();

      expect(harness.location, '/bookings/booking-1044');
    });

    testWidgets('sending to the current recipient opens the status', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      await harness.send();

      expect(harness.repository.sendCalls, <SendContractParamsEntity>[
        const SendContractParamsEntity(
          contractId: 'c1',
          channel: ContractDeliveryChannel.sms,
          address: '+77003184521',
        ),
      ]);
      expect(harness.location, '/contracts/c1/status');
    });

    testWidgets('while sending the button loads and ignores more taps', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.holdSend = true,
      );

      await tester.tap(find.text('Отправить на подпись'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(harness.repository.sendCalls, hasLength(1));
    });

    testWidgets('a send failure is shown in a snackbar and stays here', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.sendResult = const Left<Failure, ContractEntity>(
              ValidationFailure(code: ContractErrorCodes.alreadySigned),
            ),
      );

      await harness.send();

      expect(
        find.text('Договор уже подписан, изменить его нельзя'),
        findsOneWidget,
      );
      expect(harness.location, '/contracts/c1/send');
    });

    testWidgets('«Изменить» opens the sheet with the current phone', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      await harness.openSheet();

      expect(harness.sheet, findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Почта'), findsOneWidget);
      expect(find.text('Телефон'), findsOneWidget);
      expect(harness.sheetText, '700 318 45 21');
    });

    testWidgets('an incomplete phone keeps the sheet open with a message', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('WhatsApp');
      await harness.typeAddress('70112');

      await harness.confirmSheet();

      expect(harness.sheet, findsOneWidget);
      expect(find.text(FormValidators.invalidPhoneMessage), findsOneWidget);
      expect(harness.repository.sendCalls, isEmpty);
    });

    testWidgets('a new WhatsApp phone is shown and sent', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('WhatsApp');
      await harness.typeAddress('7011234567');

      await harness.confirmSheet();

      expect(harness.sheet, findsNothing);
      expect(find.text('Данияр · +7 701 ••• 45 67'), findsOneWidget);
      expect(find.text('Ссылка на договор в WhatsApp'), findsOneWidget);
      expect(harness.repository.sendCalls, isEmpty);

      await harness.send();

      expect(harness.repository.sendCalls, <SendContractParamsEntity>[
        const SendContractParamsEntity(
          contractId: 'c1',
          channel: ContractDeliveryChannel.whatsApp,
          address: '+77011234567',
        ),
      ]);
      expect(harness.location, '/contracts/c1/status');
    });

    testWidgets('an invalid email keeps the sheet open with a message', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('Почта');
      expect(find.text('Email'), findsOneWidget);
      expect(harness.sheetText, isEmpty);
      await harness.typeAddress('guest@');

      await harness.confirmSheet();

      expect(harness.sheet, findsOneWidget);
      expect(find.text(FormValidators.invalidEmailMessage), findsOneWidget);
    });

    testWidgets('an email is trimmed, shown, and sent', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('Почта');
      await harness.typeAddress(' guest@mail.kz ');

      await harness.confirmSheet();
      await harness.send();

      expect(find.text('Route /contracts/c1/status'), findsOneWidget);
      expect(harness.repository.sendCalls.single.address, 'guest@mail.kz');
      expect(
        harness.repository.sendCalls.single.channel,
        ContractDeliveryChannel.email,
      );
    });

    testWidgets('switching back to a phone channel restores the phone', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('Почта');
      await harness.typeAddress('guest@mail.kz');

      await harness.chooseChannel('SMS');

      expect(harness.sheetText, '700 318 45 21');
    });

    testWidgets('closing the sheet without «Готово» keeps the recipient', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();
      await harness.chooseChannel('Почта');
      await harness.typeAddress('guest@mail.kz');

      await tester.tapAt(const Offset(215, 20));
      await tester.pumpAndSettle();

      expect(harness.sheet, findsNothing);
      expect(find.text('Данияр · +7 700 ••• 45 21'), findsOneWidget);
    });

    testWidgets('a signed contract cannot be sent and links to its status', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) => repository.getResult =
            Right<Failure, ContractEntity>(testSignedContract()),
      );

      expect(find.text('Изменить'), findsNothing);
      expect(find.text('Отправить на подпись'), findsNothing);
      expect(find.text('Договор уже подписан'), findsOneWidget);

      await tester.tap(find.text('Статус договора'));
      await tester.pumpAndSettle();

      expect(harness.location, '/contracts/c1/status');
      expect(harness.repository.sendCalls, isEmpty);
    });
  });
}
