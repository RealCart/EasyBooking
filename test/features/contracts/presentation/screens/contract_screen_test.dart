import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/core/utils/bloc/request_status.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_entity.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_error_codes.dart';
import 'package:easy_booking/features/contracts/domain/entity/contract_guest_fields.dart';
import 'package:easy_booking/features/contracts/domain/entity/update_contract_guest_params_entity.dart';
import 'package:easy_booking/features/contracts/domain/usecases/get_contract_usecase.dart';
import 'package:easy_booking/features/contracts/domain/usecases/update_contract_guest_usecase.dart';
import 'package:easy_booking/features/contracts/presentation/bloc/contract_guest_bloc/contract_guest_bloc.dart';
import 'package:easy_booking/features/contracts/presentation/screens/contract_screen.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_load_placeholders.dart';

import '../../../../helpers/fake_contracts_repository.dart';

/// [ContractScreen] for `c1` in a small GoRouter whose `send` and `status`
/// routes only show their location.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.bloc);

  final WidgetTester tester;
  final GoRouter router;
  final FakeContractsRepository repository;
  final ContractGuestBloc bloc;

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
    final ContractGuestBloc bloc = ContractGuestBloc(
      getContract: GetContractUsecase(repository),
      updateGuest: UpdateContractGuestUsecase(repository),
    );
    final GoRouter router = GoRouter(
      initialLocation: '/contracts/c1',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.today.name,
          path: AppRoutes.today.path,
          builder: (_, _) => const Scaffold(body: Text('Today')),
        ),
        GoRoute(
          name: AppRoutes.contract.name,
          path: AppRoutes.contract.path,
          builder: (_, GoRouterState state) {
            final String id = state.pathParameters[AppRoutes.contractIdParam]!;
            // The provider owns the BLoC and closes it with the route.
            return BlocProvider<ContractGuestBloc>(
              create: (_) => bloc..add(ContractGuestRequested(id)),
              child: ContractScreen(contractId: id),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.contractSend.name,
              path: AppRoutes.contractSend.path,
              builder: (_, GoRouterState state) =>
                  Scaffold(body: Text('Route ${state.uri}')),
            ),
            GoRoute(
              name: AppRoutes.contractStatus.name,
              path: AppRoutes.contractStatus.path,
              builder: (_, GoRouterState state) =>
                  Scaffold(body: Text('Route ${state.uri}')),
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

  Finder field(String label) => find.widgetWithText(AppTextField, label);

  Finder input(String label) {
    return find.descendant(
      of: field(label),
      matching: find.byType(EditableText),
    );
  }

  String textOf(String label) {
    return tester.widget<EditableText>(input(label)).controller.text;
  }

  /// What the field draws, which differs from [textOf] while masked.
  String shownTextOf(String label) {
    return tester
        .state<EditableTextState>(input(label))
        .renderEditable
        .text!
        .toPlainText();
  }

  Future<void> type(String label, String text) async {
    await tester.enterText(input(label), text);
    await tester.pump();
  }

  Future<void> submit() async {
    await tester.tap(find.text('Перейти к условиям'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('ContractScreen', () {
    testWidgets('shows the skeleton while the contract loads', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.holdGet = true,
        settle: false,
      );

      expect(find.byType(ContractSkeleton), findsOneWidget);
      expect(find.text('Перейти к условиям'), findsNothing);
      expect(harness.repository.getCalls, <String>['c1']);
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
      expect(find.text('Перейти к условиям'), findsNothing);
    });

    testWidgets('a failed load offers a retry that loads the form', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.getResult = const Left<Failure, ContractEntity>(
              ConnectionFailure(),
            ),
      );
      expect(find.text('Не удалось загрузить договор'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);

      harness.repository.getResult = Right<Failure, ContractEntity>(
        testContract(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(harness.repository.getCalls, <String>['c1', 'c1']);
      expect(find.text('Проверим данные гостя'), findsOneWidget);
      expect(harness.textOf('Имя'), 'Данияр');
    });

    testWidgets('fills the five fields from the loaded guest', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      expect(find.text('Новый договор'), findsOneWidget);
      expect(find.text('Проверим данные гостя'), findsOneWidget);
      expect(find.text('Данияр Муратов · Samal Residence'), findsOneWidget);
      expect(
        find.text('Данные распознаны. Сверьте с документом.'),
        findsOneWidget,
      );
      expect(find.text('+7 700 ••• 45 21'), findsOneWidget);
      expect(harness.textOf('Имя'), 'Данияр');
      expect(harness.textOf('Фамилия'), 'Муратов');
      expect(harness.textOf('Отчество'), 'Ерланович');
      expect(harness.textOf('ИИН'), '960312300214');
      expect(harness.textOf('Номер удостоверения'), '048216721');
    });

    testWidgets('the IIN and ID number are masked until «Показать»', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      expect(harness.shownTextOf('ИИН'), '•••••••••214');
      expect(harness.shownTextOf('Номер удостоверения'), '•••••6721');
      expect(find.text('Показать'), findsNWidgets(2));

      await tester.tap(find.text('Показать').first);
      await tester.pump();

      expect(harness.shownTextOf('ИИН'), '960312300214');
      expect(harness.shownTextOf('Номер удостоверения'), '•••••6721');
      expect(find.text('Скрыть'), findsOneWidget);

      await tester.tap(find.text('Скрыть'));
      await tester.pump();

      expect(harness.shownTextOf('ИИН'), '•••••••••214');
      expect(find.text('Показать'), findsNWidgets(2));
    });

    testWidgets('empty required fields show messages and send nothing', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.type('Имя', '');
      await harness.type('Фамилия', '  ');
      await harness.type('ИИН', '');
      await harness.type('Номер удостоверения', '');

      await harness.submit();

      expect(find.text(FormValidators.requiredMessage), findsNWidgets(4));
      expect(harness.repository.updateCalls, isEmpty);
      expect(harness.bloc.state.submitStatus, RequestStatus.initial);
      expect(harness.location, '/contracts/c1');
    });

    testWidgets('a short IIN and ID number show messages and send nothing', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.type('ИИН', '96031230');
      await harness.type('Номер удостоверения', '0482');

      await harness.submit();

      expect(find.text(FormValidators.invalidIinMessage), findsOneWidget);
      expect(find.text(FormValidators.invalidIdNumberMessage), findsOneWidget);
      expect(harness.repository.updateCalls, isEmpty);

      // The messages clear while the user fixes the values.
      await harness.type('ИИН', '960312300215');
      expect(find.text(FormValidators.invalidIinMessage), findsNothing);
    });

    testWidgets('the IIN accepts digits only, up to twelve', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      await harness.type('ИИН', '96a0-3123002149999');

      expect(harness.textOf('ИИН'), '960312300214');
    });

    testWidgets('a valid form saves the typed data and opens the terms', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.type('Имя', 'Арман');
      await harness.type('Фамилия', 'Темирбек');
      await harness.type('Отчество', '');
      await harness.type('ИИН', '940817300631');
      await harness.type('Номер удостоверения', '043902517');

      await harness.submit();

      expect(
        harness.repository.updateCalls,
        <UpdateContractGuestParamsEntity>[
          const UpdateContractGuestParamsEntity(
            contractId: 'c1',
            firstName: 'Арман',
            lastName: 'Темирбек',
            patronymic: '',
            iin: '940817300631',
            idNumber: '043902517',
          ),
        ],
      );
      expect(harness.location, '/contracts/c1/send');
    });

    testWidgets('while saving the button loads and the fields are locked', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.holdUpdate = true,
      );

      await tester.tap(find.text('Перейти к условиям'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: harness.field('Имя'),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isFalse,
      );
      expect(harness.repository.updateCalls, hasLength(1));
    });

    testWidgets('a server field error shows under the field until edited', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.updateResult = const Left<Failure, ContractEntity>(
              ValidationFailure(
                fieldErrors: <String, String>{
                  ContractGuestFields.iin: ContractErrorCodes.invalidIin,
                },
              ),
            ),
      );

      await harness.submit();

      expect(find.text(FormValidators.invalidIinMessage), findsOneWidget);
      expect(harness.location, '/contracts/c1');

      await harness.type('ИИН', '960312300215');

      expect(find.text(FormValidators.invalidIinMessage), findsNothing);
      expect(harness.bloc.state.fieldErrors, isEmpty);
    });

    testWidgets('a signed-contract failure is shown in a snackbar', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) =>
            repository.updateResult = const Left<Failure, ContractEntity>(
              ValidationFailure(code: ContractErrorCodes.alreadySigned),
            ),
      );

      await harness.submit();

      expect(
        find.text('Договор уже подписан, изменить его нельзя'),
        findsOneWidget,
      );
      expect(harness.location, '/contracts/c1');
    });

    testWidgets('a signed contract is read-only and links to its status', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        arrange: (FakeContractsRepository repository) => repository.getResult =
            Right<Failure, ContractEntity>(testSignedContract()),
      );

      expect(find.text('Договор'), findsOneWidget);
      expect(find.text('Новый договор'), findsNothing);
      expect(find.text('Договор подписан'), findsOneWidget);
      expect(find.text('Перейти к условиям'), findsNothing);
      for (final String label in <String>[
        'Имя',
        'Фамилия',
        'Отчество',
        'ИИН',
        'Номер удостоверения',
      ]) {
        expect(
          tester.widget<EditableText>(harness.input(label)).readOnly,
          isTrue,
          reason: label,
        );
      }

      await tester.tap(find.text('Статус договора'));
      await tester.pumpAndSettle();

      expect(harness.location, '/contracts/c1/status');
      expect(harness.repository.updateCalls, isEmpty);
    });

    testWidgets('back without a previous page goes to today', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final _Harness harness = await _Harness.pump(tester);

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(harness.location, '/today');
      semantics.dispose();
    });
  });
}
