import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/billing_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_error_codes.dart';
import 'package:easy_booking/features/profile/domain/usecases/change_subscription_plan_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_billing_overview_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/billing_bloc/billing_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/billing_screen.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

/// Pushes [BillingScreen] under its own [BillingBloc], started as
/// `wrappedRoute` does.
Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<BillingBloc>(
      create: (_) => BillingBloc(
        getBillingOverview: GetBillingOverviewUsecase(repository),
        changeSubscriptionPlan: ChangeSubscriptionPlanUsecase(repository),
      )..add(const BillingRequested()),
      child: const BillingScreen(),
    ),
    settle: settle,
  );
}

final Finder _manageButton = _H.filledButton('Управлять тарифом');

Finder _inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

Future<void> _choosePlan(WidgetTester tester, String plan) async {
  await tester.tap(_manageButton);
  await tester.pumpAndSettle();
  expect(_inSheet(find.text('Выберите тариф')), findsOneWidget);
  await tester.tap(_inSheet(find.text(plan)));
  await tester.pumpAndSettle();
}

void main() {
  group('BillingScreen states', () {
    testWidgets('shows a skeleton and no plan action while loading', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdBilling = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(_H.isEnabled(tester, _manageButton), isFalse);

      repository.heldBilling.single.complete(
        Right<Failure, BillingOverviewEntity>(testBillingOverview()),
      );
      await tester.pumpAndSettle();

      expect(_H.isEnabled(tester, _manageButton), isTrue);
    });

    testWidgets('shows the plan, the usage, the card, and the invoice', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Активен'), findsOneWidget);
      expect(find.textContaining('в месяц'), findsOneWidget);
      expect(find.text('Следующее списание 15 ноября'), findsOneWidget);
      expect(find.text('4 из 10'), findsOneWidget);
      expect(find.text('3 из 5'), findsOneWidget);
      expect(find.text('Договоры с электронной подписью'), findsOneWidget);
      await tester.ensureVisible(find.text('Счёт за октябрь'));
      expect(find.text('•••• 4218'), findsOneWidget);
      expect(find.text('VISA'), findsOneWidget);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..billingResult = const Left<Failure, BillingOverviewEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить тариф'), findsOneWidget);

      repository.billingResult = Right<Failure, BillingOverviewEntity>(
        testBillingOverview(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('4 из 10'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the overview and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);
      repository.billingResult = const Left<Failure, BillingOverviewEntity>(
        ConnectionFailure(),
      );

      await tester.fling(find.text('Активен'), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      expect(repository.billingCount, 2);
      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('4 из 10'), findsOneWidget);
    });
  });

  group('BillingScreen plan change', () {
    testWidgets('picking another plan switches to it and confirms', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..changePlanResult = Right<Failure, BillingOverviewEntity>(
          testBillingOverview(plan: SubscriptionPlan.free, memberCount: 2),
        );
      await _pump(tester, repository);

      await _choosePlan(tester, 'Free');

      expect(repository.changedPlans, <SubscriptionPlan>[
        SubscriptionPlan.free,
      ]);
      expect(find.byType(BottomSheet), findsNothing);
      expect(_H.snackbar('Тариф изменён'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Бесплатно'), findsOneWidget);
      expect(find.text('2 из 2'), findsOneWidget);
    });

    testWidgets('picking the current plan changes nothing', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _choosePlan(tester, 'Pro');

      expect(repository.changedPlans, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a plan the workspace exceeds is refused with a message', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..changePlanResult = const Left<Failure, BillingOverviewEntity>(
          ValidationFailure(code: ProfileErrorCodes.planLimitExceeded),
        );
      await _pump(tester, repository);

      await _choosePlan(tester, 'Free');

      expect(
        _H.snackbar('Объектов или участников больше, чем позволяет этот тариф'),
        findsOneWidget,
      );
      expect(find.text('Pro'), findsOneWidget);
    });
  });
}
