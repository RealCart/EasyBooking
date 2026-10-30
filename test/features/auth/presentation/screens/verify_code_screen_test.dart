import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';
import 'package:easy_booking/features/auth/presentation/screens/verify_code_screen.dart';

import '../../../../helpers/fake_auth_repository.dart';

const String _phone = '+77001234567';

/// [VerifyCodeScreen] pushed over a placeholder login page in a small
/// GoRouter. The route's provider owns the BLoC; unmounting the tree at the
/// end of the test closes it and cancels its countdown.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.bloc);

  final WidgetTester tester;
  final GoRouter router;
  final FakeAuthRepository repository;
  final VerifyCodeBloc bloc;

  static Future<_Harness> pump(
    WidgetTester tester, {
    Duration resendAfter = const Duration(seconds: 30),
    void Function(FakeAuthRepository repository)? configure,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeAuthRepository repository = FakeAuthRepository();
    configure?.call(repository);
    final VerifyCodeBloc bloc = VerifyCodeBloc(
      verifyCode: VerifyCodeUsecase(repository),
      sendCode: SendCodeUsecase(repository),
    );
    final GoRouter router = GoRouter(
      initialLocation: '/login',
      routes: <RouteBase>[
        GoRoute(
          name: AppRoutes.login.name,
          path: AppRoutes.login.path,
          builder: (_, _) => const Scaffold(body: Text('Login page')),
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.verifyCode.name,
              path: AppRoutes.verifyCode.path,
              builder: (_, _) => BlocProvider<VerifyCodeBloc>(
                create: (_) => bloc
                  ..add(
                    VerifyCodeStarted(phone: _phone, resendAfter: resendAfter),
                  ),
                child: const VerifyCodeScreen(phone: _phone),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    router.pushNamed(AppRoutes.verifyCode.name);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return _Harness(tester, router, repository, bloc);
  }

  Finder get codeInput => find.byType(TextField);

  TextField get codeField => tester.widget<TextField>(codeInput);

  bool get isConfirmEnabled {
    return tester.widget<FilledButton>(find.byType(FilledButton)).onPressed !=
        null;
  }

  Future<void> typeCode(String code) async {
    await tester.enterText(codeInput, code);
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the number the code was sent to', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(tester);

    expect(find.text('Подтверждение'), findsOneWidget);
    expect(find.text('Введите код из SMS'), findsOneWidget);
    expect(find.text('Отправили на +7 700 123 45 67'), findsOneWidget);
    expect(
      find.text(
        'Код действует 5 минут. Никому не сообщайте его, даже сотрудникам '
        'поддержки.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('six digits submit automatically', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.typeCode('12345');
    expect(harness.repository.verifyCalls, isEmpty);
    expect(harness.isConfirmEnabled, isFalse);

    await harness.typeCode('123456');

    expect(harness.repository.verifyCalls, <({String phone, String code})>[
      (phone: _phone, code: '123456'),
    ]);
  });

  testWidgets('the field is read-only and confirm loads while verifying', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      configure: (FakeAuthRepository repository) {
        repository.holdVerifyCode = true;
      },
    );

    await harness.typeCode('123456');

    expect(harness.codeField.readOnly, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(harness.isConfirmEnabled, isFalse);

    harness.repository.heldVerifyCodes.single.complete(
      const Left<Failure, void>(
        ValidationFailure(code: AuthErrorCodes.invalidCode),
      ),
    );
    await tester.pump();

    expect(harness.codeField.readOnly, isFalse);
  });

  testWidgets('a verify failure shows its text and clears the boxes', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      configure: (FakeAuthRepository repository) {
        repository.holdVerifyCode = true;
      },
    );
    await harness.typeCode('123456');

    harness.repository.heldVerifyCodes.single.complete(
      const Left<Failure, void>(
        ValidationFailure(code: AuthErrorCodes.codeExpired),
      ),
    );
    await tester.pump();

    expect(find.text('Код истёк. Запросите новый'), findsOneWidget);
    expect(harness.codeField.controller!.text, isEmpty);
    expect(find.text('1'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);

    await harness.typeCode('4');

    expect(find.text('Код истёк. Запросите новый'), findsNothing);
    expect(harness.bloc.state.code, '4');
  });

  // Known lib bug: when the failure arrives before the next frame, the
  // field is rebuilt with the same `code` ('') as its last build, so
  // `OtpCodeField.didUpdateWidget` does not sync the controller and the
  // boxes keep showing the rejected digits while the BLoC code is empty.
  testWidgets('a verify failure in the same frame also clears the boxes', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      configure: (FakeAuthRepository repository) {
        repository.verifyCodeResult = const Left<Failure, void>(
          ValidationFailure(code: AuthErrorCodes.codeExpired),
        );
      },
    );

    await harness.typeCode('123456');
    await tester.pump();

    expect(find.text('Код истёк. Запросите новый'), findsOneWidget);
    expect(harness.bloc.state.code, isEmpty);
    expect(harness.codeField.controller!.text, isEmpty);
  });

  testWidgets('the resend row counts down', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    expect(find.text('Можно через 00:30'), findsOneWidget);
    expect(find.text('Отправить код повторно'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Можно через 00:29'), findsOneWidget);
    expect(find.text('00:29'), findsOneWidget);
    expect(harness.bloc.state.resendAvailableIn, const Duration(seconds: 29));
  });

  testWidgets('resend is blocked during the countdown, then restarts it', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      resendAfter: const Duration(seconds: 2),
    );

    await tester.tap(find.text('Отправить код повторно'));
    await tester.pump();
    expect(harness.repository.sentPhones, isEmpty);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Можно через'), findsNothing);

    harness.repository.resendAfter = const Duration(seconds: 60);
    await tester.tap(find.text('Отправить код повторно'));
    await tester.pump();

    expect(harness.repository.sentPhones, <String>[_phone]);
    expect(find.text('Можно через 01:00'), findsOneWidget);
  });

  testWidgets('a resend failure shows a snackbar', (WidgetTester tester) async {
    await _Harness.pump(
      tester,
      resendAfter: Duration.zero,
      configure: (FakeAuthRepository repository) {
        repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
          ServerFailure(statusCode: 429),
        );
      },
    );

    await tester.tap(find.text('Отправить код повторно'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Слишком много попыток. Попробуйте позже'),
      findsOneWidget,
    );
  });

  testWidgets('«Изменить номер телефона» pops back to login', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.text('Изменить номер телефона'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, '/login');
    expect(find.text('Login page'), findsOneWidget);
    expect(find.byType(VerifyCodeScreen), findsNothing);
  });

  testWidgets('the header back button also pops to login', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(harness.router.state.uri.path, '/login');
  });
}
