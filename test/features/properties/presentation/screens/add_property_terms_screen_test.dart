import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/core/utils/money_formatter.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_draft_entity.dart';
import 'package:easy_booking/features/properties/domain/entity/add_property_fields.dart';
import 'package:easy_booking/features/properties/domain/entity/property_error_codes.dart';
import 'package:easy_booking/features/properties/domain/entity/property_terms_entity.dart';
import 'package:easy_booking/features/properties/presentation/screens/add_property_terms_screen.dart';

import '../../../../helpers/add_property_step_harness.dart';
import '../../../../helpers/fake_property_management_repository.dart';

typedef _H = AddPropertyStepHarness;

const String _publish = 'Добавить квартиру';
const String _stepLocation = '/add-property/channels/terms';

const String _price = 'Цена за ночь';
const String _deposit = 'Депозит';
const String _checkIn = 'Заезд после';
const String _checkOut = 'Выезд до';
const String _minNights = 'Минимум ночей';
const String _cleaning = 'Уборка';

/// Step 3 above steps 1 and 2, and the confirmation it opens.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakePropertyManagementRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    initialLocation: _stepLocation,
    settle: settle,
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.addProperty.name,
        path: AppRoutes.addProperty.path,
        builder: (_, GoRouterState state) => _H.destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.addPropertyChannels.name,
            path: AppRoutes.addPropertyChannels.path,
            builder: (_, GoRouterState state) => _H.destination(state),
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.addPropertyTerms.name,
                path: AppRoutes.addPropertyTerms.path,
                builder: (_, _) =>
                    _H.provide(repository, const AddPropertyTermsScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: AppRoutes.property.name,
        path: AppRoutes.property.path,
        builder: (_, GoRouterState state) => _H.destination(state),
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.propertyReady.name,
            path: AppRoutes.propertyReady.path,
            builder: (_, GoRouterState state) => _H.destination(state),
          ),
        ],
      ),
    ],
  );
}

/// A draft that went through steps 1 and 2.
FakePropertyManagementRepository _filled() {
  return FakePropertyManagementRepository()
    ..draftResult = const Right<Failure, AddPropertyDraftEntity>(
      testFilledDraft,
    );
}

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(_H.button(_publish));
  await tester.tap(_H.button(_publish));
  await tester.pumpAndSettle();
}

void main() {
  group('AddPropertyTermsScreen', () {
    testWidgets(
      'shows a skeleton and a disabled button until the draft loads',
      (
        WidgetTester tester,
      ) async {
        final FakePropertyManagementRepository repository = _filled()
          ..holdDraft = true;

        await _pump(tester, repository, settle: false);

        expect(find.byType(AppSkeleton), findsWidgets);
        expect(find.text(_price), findsNothing);
        expect(_H.isEnabled(tester, _publish), isFalse);

        repository.heldDraft.single.complete(
          const Right<Failure, AddPropertyDraftEntity>(testFilledDraft),
        );
        await tester.pumpAndSettle();

        expect(find.text(_price), findsOneWidget);
        expect(_H.isEnabled(tester, _publish), isTrue);
      },
    );

    testWidgets('a failed draft load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled()
        ..draftResult = const Left<Failure, AddPropertyDraftEntity>(
          StorageFailure(),
        );

      await _pump(tester, repository);

      expect(find.text('Не удалось загрузить черновик'), findsOneWidget);
      expect(_H.isEnabled(tester, _publish), isFalse);

      repository.draftResult = const Right<Failure, AddPropertyDraftEntity>(
        testFilledDraft,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(_H.textOf(tester, _minNights), '2');
    });

    testWidgets('is prefilled with the terms of the draft', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _filled());

      expect(_H.textOf(tester, _price), MoneyFormatter.group(42500));
      expect(_H.textOf(tester, _deposit), MoneyFormatter.group(50000));
      expect(_H.textOf(tester, _checkIn), '14:00');
      expect(_H.textOf(tester, _checkOut), '12:00');
      expect(_H.textOf(tester, _minNights), '2');
      expect(_H.textOf(tester, _cleaning), MoneyFormatter.group(8000));
    });

    testWidgets('publishes the prefilled terms and opens the confirmation', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled();
      final GoRouter router = await _pump(tester, repository);

      await _submit(tester);

      expect(repository.publishedTerms.single, testTerms);
      expect(_H.location(router), '/properties/new-property-1/ready');
      expect(find.byType(AddPropertyTermsScreen), findsNothing);
    });

    testWidgets('publishes edited amounts, with no deposit or cleaning', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled();
      await _pump(tester, repository);

      await _H.enter(tester, _price, '30 000');
      await _H.enter(tester, _deposit, '0');
      await _H.enter(tester, _minNights, '30');
      await _H.enter(tester, _cleaning, '0 ₸');
      await _submit(tester);

      expect(
        repository.publishedTerms.single,
        const PropertyTermsEntity(
          pricePerNight: 30000,
          deposit: 0,
          checkInTime: Duration(hours: 14),
          checkOutTime: Duration(hours: 12),
          minNights: 30,
          cleaningFee: 0,
        ),
      );
    });

    testWidgets('invalid values show their messages and publish nothing', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled();
      final GoRouter router = await _pump(tester, repository);

      await _H.enter(tester, _price, '0');
      await _H.enter(tester, _deposit, '');
      await _H.enter(tester, _minNights, '31');
      await _H.enter(tester, _cleaning, 'abc');
      await _submit(tester);

      expect(
        find.text(FormValidators.invalidAmountMessage),
        findsNWidgets(2),
      );
      expect(find.text(FormValidators.requiredMessage), findsOneWidget);
      expect(find.text('Введите число от 1 до 30'), findsOneWidget);
      expect(repository.publishedTerms, isEmpty);
      expect(_H.location(router), _stepLocation);
    });

    testWidgets('zero minimum nights is rejected', (WidgetTester tester) async {
      final FakePropertyManagementRepository repository = _filled();
      await _pump(tester, repository);

      await _H.enter(tester, _minNights, '0');
      await _submit(tester);

      expect(find.text('Введите число от 1 до 30'), findsOneWidget);
      expect(repository.publishedTerms, isEmpty);
    });

    testWidgets('an incomplete draft shows a snackbar and stays', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled()
        ..publishResult = const Left<Failure, String>(
          ValidationFailure(code: PropertyErrorCodes.draftIncomplete),
        );
      final GoRouter router = await _pump(tester, repository);

      await _submit(tester);

      expect(
        find.text('Сначала заполните название и адрес квартиры'),
        findsOneWidget,
      );
      expect(_H.location(router), _stepLocation);
      expect(_H.isEnabled(tester, _publish), isTrue);
    });

    testWidgets('server field errors show under their fields until edited', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled()
        ..publishResult = const Left<Failure, String>(
          ValidationFailure(
            fieldErrors: <String, String>{
              AddPropertyFields.pricePerNight: PropertyErrorCodes.outOfRange,
            },
          ),
        );
      await _pump(tester, repository);

      await _submit(tester);
      expect(find.text('Значение вне допустимых пределов'), findsOneWidget);

      await _H.enter(tester, _price, '45 000');
      await tester.pumpAndSettle();
      expect(find.text('Значение вне допустимых пределов'), findsNothing);
    });

    testWidgets('the button is busy while publishing and ignores taps', (
      WidgetTester tester,
    ) async {
      final FakePropertyManagementRepository repository = _filled()
        ..holdPublish = true;
      final GoRouter router = await _pump(tester, repository);

      await tester.ensureVisible(_H.button(_publish));
      await tester.tap(_H.button(_publish));
      await tester.pump();
      final Finder busyButton = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(busyButton).onPressed, isNull);
      await tester.tap(busyButton, warnIfMissed: false);
      await tester.pump();
      expect(repository.publishedTerms, hasLength(1));

      repository.heldPublish.single.complete(
        const Right<Failure, String>('new-property-3'),
      );
      await tester.pumpAndSettle();
      expect(_H.location(router), '/properties/new-property-3/ready');
    });

    testWidgets('back returns to step 2', (WidgetTester tester) async {
      final GoRouter router = await _pump(tester, _filled());

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      expect(_H.location(router), '/add-property/channels');
    });
  });
}
