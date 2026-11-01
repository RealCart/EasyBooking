import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_choice_chip.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/error/failure_message.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_type.dart';
import 'package:easy_booking/features/properties/domain/entity/save_add_property_details_params_entity.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_screen.dart';

import '../../../../helpers/add_property_step_harness.dart';
import '../../../../helpers/fake_property_management_repository.dart';

typedef _H = AddPropertyStepHarness;

const String _continue = 'Продолжить';
const String _outOfRangeMessage = 'Значение вне допустимых пределов';

/// Step 1 at `/add-property`, step 2 above it, and the property list.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertyManagementRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    initialLocation: AppRoutes.addProperty.path,
    settle: settle,
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.properties.name,
        path: AppRoutes.properties.path,
        builder: (_, GoRouterState state) => _H.destination(state),
      ),
      GoRoute(
        name: AppRoutes.addProperty.name,
        path: AppRoutes.addProperty.path,
        builder: (_, _) => _H.provide(repository, const AddPropertyScreen()),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.addPropertyChannels.name,
            path: AppRoutes.addPropertyChannels.path,
            builder: (_, GoRouterState state) => _H.destination(state),
          ),
        ],
      ),
    ],
  );
}

bool _isChipSelected(WidgetTester tester, String label) {
  return tester
      .widget<AppChoiceChip>(find.widgetWithText(AppChoiceChip, label))
      .isSelected;
}

void main() {
  group('AddPropertyScreen', () {
    testWidgets(
      'shows a skeleton and a disabled button until the draft loads',
      (
        WidgetTester tester,
      ) async {
        final FakePropertyManagementRepository repository =
            FakePropertyManagementRepository()..holdDraft = true;

        await _pump(tester, repository, settle: false);

        expect(find.byType(AppSkeleton), findsWidgets);
        expect(find.text('Название'), findsNothing);
        expect(_H.isEnabled(tester, _continue), isFalse);

        repository.heldDraft.single.complete(
          const Right<Failure, AddPropertyDraftEntity>(testEmptyDraft),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppSkeleton), findsNothing);
        expect(find.text('Название'), findsOneWidget);
        expect(_H.isEnabled(tester, _continue), isTrue);
      },
    );

    testWidgets('a failed draft load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Left<Failure, AddPropertyDraftEntity>(
              StorageFailure(),
            );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить черновик'), findsOneWidget);
      expect(find.text(const StorageFailure().userMessage), findsOneWidget);
      expect(_H.isEnabled(tester, _continue), isFalse);

      repository.draftResult = const Right<Failure, AddPropertyDraftEntity>(
        testFilledDraft,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(repository.draftCount, 2);
      expect(find.text('Не удалось загрузить черновик'), findsNothing);
      expect(_H.textOf(tester, 'Название'), testFilledDraft.title);
      expect(_H.isEnabled(tester, _continue), isTrue);
    });

    testWidgets('is prefilled from the draft', (WidgetTester tester) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
              testFilledDraft,
            );

      await _pump(tester, repository);

      expect(_H.textOf(tester, 'Название'), 'Al-Farabi Residence · 19');
      expect(_H.textOf(tester, 'Адрес'), 'Аль-Фараби, 21');
      expect(_isChipSelected(tester, 'Дом'), isTrue);
      expect(_isChipSelected(tester, 'Квартира'), isFalse);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('an empty form shows the required messages and sends nothing', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(find.text(FormValidators.requiredMessage), findsNWidgets(2));
      expect(repository.savedDetails, isEmpty);
      expect(_H.location(router), AppRoutes.addProperty.path);
    });

    testWidgets('a valid form saves the details and opens step 2', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      final GoRouter router = await _pump(tester, repository);

      await _H.enter(tester, 'Название', 'Highvill · 5');
      await _H.enter(tester, 'Адрес', 'Кабанбай батыра, 11');
      await _H.tapVisible(
        tester,
        find.widgetWithText(AppChoiceChip, 'Комната'),
      );
      await _H.tapVisible(tester, find.bySemanticsLabel('Больше комнат'));
      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(
        repository.savedDetails.single,
        const SaveAddPropertyDetailsParamsEntity(
          title: 'Highvill · 5',
          address: 'Кабанбай батыра, 11',
          type: PropertyType.room,
          rooms: 3,
        ),
      );
      expect(_H.location(router), '/add-property/channels');
    });

    testWidgets('fixing the fields after a failed submit clears the errors', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository();
      await _pump(tester, repository);
      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      await _H.enter(tester, 'Название', 'Highvill · 5');
      await tester.pumpAndSettle();

      expect(find.text(FormValidators.requiredMessage), findsOneWidget);
    });

    testWidgets('server field errors show under their fields until edited', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
              testFilledDraft,
            )
            ..saveDetailsResult = const Left<Failure, void>(
              ValidationFailure(
                fieldErrors: <String, String>{
                  AddPropertyFields.title: PropertyErrorCodes.outOfRange,
                  AddPropertyFields.rooms: PropertyErrorCodes.outOfRange,
                },
              ),
            );
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(find.text(_outOfRangeMessage), findsNWidgets(2));
      expect(_H.location(router), AppRoutes.addProperty.path);

      await _H.enter(tester, 'Название', 'Highvill · 5');
      await tester.pumpAndSettle();
      expect(find.text(_outOfRangeMessage), findsOneWidget);

      await _H.tapVisible(tester, find.bySemanticsLabel('Меньше комнат'));
      expect(find.text(_outOfRangeMessage), findsNothing);
    });

    testWidgets('a general failure shows a snackbar and stays', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
              testFilledDraft,
            )
            ..saveDetailsResult = const Left<Failure, void>(
              ConnectionFailure(),
            );
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pumpAndSettle();

      expect(find.text(const ConnectionFailure().userMessage), findsOneWidget);
      expect(_H.location(router), AppRoutes.addProperty.path);
    });

    testWidgets('the button is busy while saving and ignores taps', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository =
          FakePropertyManagementRepository()
            ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
              testFilledDraft,
            )
            ..holdSaveDetails = true;
      final GoRouter router = await _pump(tester, repository);

      await tester.tap(_H.button(_continue));
      await tester.pump();
      final Finder busyButton = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(busyButton).onPressed, isNull);
      await tester.tap(busyButton, warnIfMissed: false);
      await tester.pump();
      expect(repository.savedDetails, hasLength(1));

      repository.heldSaveDetails.single.complete(
        const Right<Failure, void>(null),
      );
      await tester.pumpAndSettle();
      expect(_H.location(router), '/add-property/channels');
    });

    testWidgets('back without a screen beneath opens the property list', (
      WidgetTester tester,
    ) async {
      final GoRouter router = await _pump(
        tester,
        FakePropertyManagementRepository(),
      );

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(_H.location(router), AppRoutes.properties.path);
    });
  });
}
