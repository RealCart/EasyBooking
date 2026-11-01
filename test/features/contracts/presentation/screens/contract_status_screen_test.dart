import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_recipient_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/send_contract_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/send_contract_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_status_bloc/contract_status_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_status_screen.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_timeline.dart';

import '../../../../helpers/fake_contracts_repository.dart';

/// [ContractStatusScreen] for `c1` at `/contracts/c1/status` in a small
/// GoRouter whose other routes only show their location.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.bloc);

  final WidgetTester tester;
  final GoRouter router;
  final FakeContractsRepository repository;
  final ContractStatusBloc bloc;

  static Future<_Harness> pump(
    WidgetTester tester, {
    ContractEntity? contract,
    void Function(FakeContractsRepository repository)? arrange,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeContractsRepository repository = FakeContractsRepository()
      ..getResult = Right<Failure, ContractEntity>(
        contract ?? testSentContract(),
      );
    arrange?.call(repository);
    final ContractStatusBloc bloc = ContractStatusBloc(
      getContract: GetContractUsecase(repository),
      sendContract: SendContractUsecase(repository),
    );
    Widget placeholder(BuildContext _, GoRouterState state) {
      return Scaffold(body: Text('Route ${state.uri}'));
    }

    final GoRouter router = GoRouter(
      initialLocation: '/contracts/c1/status',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.contract.name,
          path: AppRoutes.contract.path,
          builder: placeholder,
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.contractSend.name,
              path: AppRoutes.contractSend.path,
              builder: placeholder,
            ),
            GoRoute(
              name: AppRoutes.contractStatus.name,
              path: AppRoutes.contractStatus.path,
              builder: (_, GoRouterState state) {
                final String id =
                    state.pathParameters[AppRoutes.contractIdParam]!;
                return BlocProvider<ContractStatusBloc>(
                  create: (_) => bloc..add(ContractStatusRequested(id)),
                  child: ContractStatusScreen(contractId: id),
                );
              },
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

  List<ContractTimelineStep> get steps {
    return tester.widget<ContractTimeline>(find.byType(ContractTimeline)).steps;
  }
}

void main() {
  group('ContractStatusScreen', () {
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
      expect(find.text('PDF'), findsNothing);
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
              ServerFailure(statusCode: 500),
            ),
      );
      expect(find.text('Не удалось загрузить договор'), findsOneWidget);

      harness.repository.getResult = Right<Failure, ContractEntity>(
        testSentContract(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(harness.repository.getCalls, <String>['c1', 'c1']);
      expect(find.text('Договор № EB-1053'), findsOneWidget);
    });

    testWidgets('a sent contract shows its history and the pending signature', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      expect(find.text('Ожидает подписи гостя'), findsOneWidget);
      expect(find.text('Договор № EB-1053'), findsOneWidget);
      expect(
        find.text('Данияр Муратов · Samal Residence\n22–24 октября · 2 ночи'),
        findsOneWidget,
      );
      expect(
        harness.steps.map(
          (ContractTimelineStep step) =>
              (step.title, step.subtitle, step.isPending),
        ),
        <(String, String, bool)>[
          ('Создан', 'Сегодня, 09:36', false),
          ('Отправлен по SMS', 'Сегодня, 09:40 · +7 700 ••• 45 21', false),
          ('Ожидаем подпись', 'Напомнить через 2 часа', true),
        ],
      );
      expect(find.text('Напомнить через 2 часа'), findsOneWidget);
      expect(
        find.text('Гость получит новую безопасную ссылку.'),
        findsOneWidget,
      );
      expect(find.text('Отправить повторно'), findsOneWidget);
    });

    testWidgets('«Скопировать ссылку» copies the link and confirms', (
      WidgetTester tester,
    ) async {
      final List<Object?> copied = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map<Object?, Object?>)['text']);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _Harness.pump(tester);

      await tester.tap(find.text('Скопировать ссылку'));
      await tester.pumpAndSettle();

      expect(copied, <Object?>[testSigningUrl]);
      expect(find.text('Ссылка скопирована'), findsOneWidget);
    });

    testWidgets('«Отправить повторно» resends to the recipient', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      await tester.tap(find.text('Отправить повторно'));
      await tester.pumpAndSettle();

      expect(harness.repository.sendCalls, <SendContractParamsEntity>[
        const SendContractParamsEntity(
          contractId: 'c1',
          channel: ContractDeliveryChannel.sms,
          address: '+77003184521',
        ),
      ]);
      expect(find.text('Ссылка отправлена повторно'), findsOneWidget);
    });

    testWidgets('while resending the button loads and ignores more taps', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.holdSend = true,
      );

      await tester.tap(find.text('Отправить повторно'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(harness.repository.sendCalls, hasLength(1));
    });

    testWidgets('a failed resend is shown in a snackbar', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.sendResult = const Left<Failure, ContractEntity>(
              ConnectionFailure(),
            ),
      );

      await tester.tap(find.text('Отправить повторно'));
      await tester.pumpAndSettle();

      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('Ссылка отправлена повторно'), findsNothing);
    });

    testWidgets('a failed refresh keeps the contract and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      harness.repository.getResult = const Left<Failure, ContractEntity>(
        ConnectionFailure(),
      );

      harness.bloc.add(const ContractStatusRequested('c1'));
      await tester.pumpAndSettle();

      expect(find.text('Договор № EB-1053'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('Не удалось загрузить договор'), findsNothing);
    });

    testWidgets('a draft waits for sending and opens the send step', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        contract: testContract(),
      );

      expect(find.text('Черновик · не отправлен'), findsOneWidget);
      expect(harness.steps.last.title, 'Ожидаем отправку');
      expect(harness.steps.last.isPending, isTrue);
      expect(find.text('Скопировать ссылку'), findsNothing);
      expect(find.text('Отправить повторно'), findsNothing);

      await tester.tap(find.text('Отправить на подпись'));
      await tester.pumpAndSettle();

      expect(harness.location, '/contracts/c1/send');
    });

    testWidgets('a signed contract has no pending step and no footer', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        contract: testSignedContract(),
      );

      expect(find.text('Подписан гостем'), findsOneWidget);
      expect(
        harness.steps.map((ContractTimelineStep step) => step.title),
        <String>['Создан', 'Отправлен по SMS', 'Открыт гостем', 'Подписан'],
      );
      expect(
        harness.steps.any((ContractTimelineStep step) => step.isPending),
        isFalse,
      );
      expect(harness.steps.last.subtitle, 'Вчера, 12:10');
      expect(find.text('Отправить повторно'), findsNothing);
      expect(find.text('Отправить на подпись'), findsNothing);
      expect(find.text('Скопировать ссылку'), findsOneWidget);
    });
  });
}
