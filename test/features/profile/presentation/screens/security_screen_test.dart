import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/profile/domain/entity/security_overview_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_security_overview_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/set_biometric_login_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/terminate_other_sessions_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/security_bloc/security_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/security_screen.dart';
import 'package:easy_booking/features/profile/presentation/widgets/profile_toggle_row.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

/// Pushes [SecurityScreen] under its own [SecurityBloc], started as
/// `wrappedRoute` does.
Future<void> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<SecurityBloc>(
      create: (_) => SecurityBloc(
        getSecurityOverview: GetSecurityOverviewUsecase(repository),
        setBiometricLogin: SetBiometricLoginUsecase(repository),
        terminateOtherSessions: TerminateOtherSessionsUsecase(repository),
      )..add(const SecurityRequested()),
      child: const SecurityScreen(),
    ),
    settle: settle,
  );
}

final Finder _faceIdRow = find.widgetWithText(
  ProfileToggleRow,
  'Вход по Face ID',
);

final Finder _terminateAction = find.text('Завершить другие сеансы');

ProfileToggleRow _faceId(WidgetTester tester) {
  return tester.widget<ProfileToggleRow>(_faceIdRow);
}

Future<void> _confirmTerminate(WidgetTester tester, String answer) async {
  await _H.tapVisible(tester, _terminateAction);
  expect(find.text('Завершить другие сеансы?'), findsOneWidget);
  await tester.tap(find.text(answer));
  await tester.pumpAndSettle();
}

void main() {
  group('SecurityScreen states', () {
    testWidgets('shows a skeleton while loading', (WidgetTester tester) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdSecurity = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);

      repository.heldSecurity.single.complete(
        Right<Failure, SecurityOverviewEntity>(testSecurityOverview()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
    });

    testWidgets('shows the sign-in methods and the sessions', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(find.text('Номер телефона'), findsOneWidget);
      expect(find.text('+7 701 234 56 78 · подтверждён'), findsOneWidget);
      expect(find.text('Изменён 3 сентября'), findsOneWidget);
      expect(_faceId(tester).value, isTrue);
      expect(find.text('АКТИВНЫЕ СЕАНСЫ · 2'), findsOneWidget);
      expect(find.text('iPhone 15 Pro'), findsOneWidget);
      expect(find.text('Этот'), findsOneWidget);
      expect(find.text('MacBook Air'), findsOneWidget);
      await tester.ensureVisible(_terminateAction);
      expect(
        find.text('Потребуется повторный вход на MacBook Air.'),
        findsOneWidget,
      );
    });

    testWidgets('«Последние действия» are dated relative to the source time', (
      WidgetTester tester,
    ) async {
      // The source answered at 14:00 on 22 October, the day of the sign-in.
      await _pump(tester, FakeProfileRepository());

      await tester.ensureVisible(find.text('Код приложения изменён'));
      expect(find.text('ПОСЛЕДНИЕ ДЕЙСТВИЯ'), findsOneWidget);
      expect(find.text('Успешный вход'), findsOneWidget);
      expect(find.text('Сегодня, 09:41 · iPhone'), findsOneWidget);
      expect(find.text('3 сентября, 18:20'), findsOneWidget);
    });

    testWidgets('a sign-in of the day before the source time is «Вчера»', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..securityResult = Right<Failure, SecurityOverviewEntity>(
          testSecurityOverview(receivedAt: DateTime(2026, 10, 23, 8)),
        );

      await _pump(tester, repository);

      await tester.ensureVisible(find.text('Успешный вход'));
      expect(find.text('Вчера, 09:41 · iPhone'), findsOneWidget);
    });

    testWidgets('a failed first load offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..securityResult = const Left<Failure, SecurityOverviewEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить настройки'), findsOneWidget);

      repository.securityResult = Right<Failure, SecurityOverviewEntity>(
        testSecurityOverview(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('iPhone 15 Pro'), findsOneWidget);
    });

    testWidgets('a failed refresh keeps the overview and shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);
      repository.securityResult = const Left<Failure, SecurityOverviewEntity>(
        ConnectionFailure(),
      );

      await tester.fling(
        find.text('Номер телефона'),
        const Offset(0, 400),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repository.securityCount, 2);
      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('iPhone 15 Pro'), findsOneWidget);
    });
  });

  group('SecurityScreen Face ID', () {
    testWidgets('the switch shows the saved value once confirmed', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdBiometric = true;
      await _pump(tester, repository);

      await tester.tap(_faceIdRow);
      await tester.pump();

      expect(repository.biometricValues, <bool>[false]);
      expect(_faceId(tester).onChanged, isNull);
      expect(_faceId(tester).value, isTrue);

      repository.heldBiometric.single.complete(
        Right<Failure, SecurityOverviewEntity>(
          testSecurityOverview(isBiometricLoginEnabled: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(_faceId(tester).value, isFalse);
      expect(_faceId(tester).onChanged, isNotNull);
    });

    testWidgets('a failed switch keeps the value and shows the failure', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..biometricResult = const Left<Failure, SecurityOverviewEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      await tester.tap(_faceIdRow);
      await tester.pumpAndSettle();

      expect(_faceId(tester).value, isTrue);
      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
    });
  });

  group('SecurityScreen other sessions', () {
    testWidgets('is hidden when there are no other sessions', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..securityResult = Right<Failure, SecurityOverviewEntity>(
          testSecurityOverview(hasOtherSession: false),
        );
      await _pump(tester, repository);

      expect(_terminateAction, findsNothing);
    });

    testWidgets('cancelling the confirmation keeps the sessions', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _confirmTerminate(tester, 'Отмена');

      expect(repository.terminateCount, 0);
      expect(find.text('MacBook Air'), findsOneWidget);
    });

    testWidgets('confirming ends the other sessions and confirms', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      await _pump(tester, repository);

      await _confirmTerminate(tester, 'Завершить');

      expect(repository.terminateCount, 1);
      expect(_H.snackbar('Другие сеансы завершены'), findsOneWidget);
      expect(find.text('MacBook Air'), findsNothing);
      expect(_terminateAction, findsNothing);
    });

    testWidgets('a failure keeps the sessions and shows it', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..terminateResult = const Left<Failure, SecurityOverviewEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      await _confirmTerminate(tester, 'Завершить');

      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
      expect(find.text('MacBook Air'), findsOneWidget);
    });
  });
}
