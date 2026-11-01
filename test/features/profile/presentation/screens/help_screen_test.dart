import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/help_center_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_help_center_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/help_bloc/help_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/help_screen.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

/// Pushes [HelpScreen] under its own [HelpBloc], started as `wrappedRoute`
/// does.
Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<HelpBloc>(
      create: (_) =>
          HelpBloc(getHelpCenter: GetHelpCenterUsecase(repository))
            ..add(const HelpRequested()),
      child: const HelpScreen(),
    ),
    settle: settle,
  );
}

final Finder _searchInput = find.descendant(
  of: find.byType(AppSearchField),
  matching: find.byType(TextField),
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(_searchInput, query);
  await tester.pumpAndSettle();
}

void main() {
  group('HelpScreen states', () {
    testWidgets('shows a skeleton while loading', (WidgetTester tester) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdHelp = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.byType(AppSearchField), findsNothing);

      repository.heldHelp.single.complete(
        const Right<Failure, HelpCenterEntity>(testHelpCenter),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
    });

    testWidgets('shows the support chat, the topics, and the guides', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(find.text('Поддержка EasyBooking'), findsOneWidget);
      expect(find.text('Обычно отвечаем за 10 минут'), findsOneWidget);
      expect(find.text('Синхронизация календарей'), findsOneWidget);
      expect(find.text('Оплата и тариф'), findsOneWidget);
      await tester.ensureVisible(find.text('Как подключить Airbnb'));
      expect(find.text('4 минуты'), findsOneWidget);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..helpResult = const Left<Failure, HelpCenterEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить помощь'), findsOneWidget);

      repository.helpResult = const Right<Failure, HelpCenterEntity>(
        testHelpCenter,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Синхронизация календарей'), findsOneWidget);
      expect(repository.helpCount, 2);
    });
  });

  group('HelpScreen search', () {
    testWidgets('filters the topics and guides on the screen', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _search(tester, 'карты');

      expect(find.text('Оплата и тариф'), findsOneWidget);
      expect(find.text('Синхронизация календарей'), findsNothing);
      expect(find.text('Как подключить Airbnb'), findsNothing);
      expect(find.text('Поддержка EasyBooking'), findsOneWidget);
      expect(repository.helpCount, 1);
    });

    testWidgets('no match shows «Ничего не нашли»', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      await _search(tester, 'бассейн');

      expect(find.text('Ничего не нашли'), findsOneWidget);
      expect(find.text('Синхронизация календарей'), findsNothing);
    });

    testWidgets('clearing the query shows everything again', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());
      await _search(tester, 'бассейн');

      await _search(tester, '');

      expect(find.text('Ничего не нашли'), findsNothing);
      expect(find.text('Синхронизация календарей'), findsOneWidget);
      expect(find.text('Оплата и тариф'), findsOneWidget);
    });

    testWidgets('a topic says it is coming soon', (WidgetTester tester) async {
      await _pump(tester, FakeProfileRepository());

      await tester.tap(find.text('Оплата и тариф'));
      await tester.pump();

      expect(_H.snackbar('Скоро будет'), findsOneWidget);
    });
  });
}
