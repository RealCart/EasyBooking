import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/utils/form_validators.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/otp_challenge_entity.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:easy_booking/features/auth/presentation/screens/login_screen.dart';

import '../../../../helpers/fake_auth_repository.dart';

/// [LoginScreen] in a small GoRouter: `/home` → `/login` → `/login/verify`.
/// The verify route only shows its query so navigation can be checked.
final class _Harness {
  _Harness(this.tester, this.router, this.repository, this.bloc);

  final WidgetTester tester;
  final GoRouter router;
  final FakeAuthRepository repository;
  final LoginBloc bloc;

  static Future<_Harness> pump(
    WidgetTester tester, {
    String initialLocation = '/login',
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeAuthRepository repository = FakeAuthRepository();
    final LoginBloc bloc = LoginBloc(sendCode: SendCodeUsecase(repository));
    final GoRouter router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (_, _) => const Text('Home page')),
        GoRoute(
          name: AppRoutes.login.name,
          path: AppRoutes.login.path,
          // The provider owns the BLoC and closes it with the route.
          builder: (_, GoRouterState state) => BlocProvider<LoginBloc>(
            create: (_) => bloc,
            child: LoginScreen(
              from: state.uri.queryParameters[AppRoutes.fromQuery],
            ),
          ),
          routes: <RouteBase>[
            GoRoute(
              name: AppRoutes.verifyCode.name,
              path: AppRoutes.verifyCode.path,
              builder: (_, GoRouterState state) =>
                  Scaffold(body: Text('Verify ${state.uri}')),
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
    return _Harness(tester, router, repository, bloc);
  }

  Finder get phoneInput => find.byType(TextField);

  Finder get submitButton => find.byType(FilledButton);

  bool get isSubmitEnabled {
    return tester.widget<FilledButton>(submitButton).onPressed != null;
  }

  String get phoneText {
    return tester.widget<TextField>(phoneInput).controller!.text;
  }

  Future<void> typePhone(String text) async {
    await tester.enterText(phoneInput, text);
    await tester.pump();
  }

  Future<void> submit() async {
    await tester.tap(submitButton);
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the login form', (WidgetTester tester) async {
    await _Harness.pump(tester);

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Добро пожаловать'), findsOneWidget);
    expect(find.text('Казахстан (+7)'), findsOneWidget);
    expect(
      find.text('Пришлём одноразовый код в SMS. Пароль не понадобится.'),
      findsOneWidget,
    );
    expect(find.text('Для владельцев и участников команды'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
    expect(find.textContaining('Условия и конфиденциальность'), findsNothing);
  });

  testWidgets('typing formats the number without touching the BLoC', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.typePhone('7001234567');

    expect(harness.phoneText, '700 123 45 67');
    expect(harness.bloc.state, const LoginState());
  });

  testWidgets('a keyboard submit of an incomplete number shows the error', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    await harness.typePhone('700123');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(FormValidators.invalidPhoneMessage), findsOneWidget);
    expect(harness.repository.sentPhones, isEmpty);

    // The error clears as soon as the number becomes valid.
    await harness.typePhone('7001234567');
    expect(find.text(FormValidators.invalidPhoneMessage), findsNothing);
  });

  testWidgets('a keyboard submit of a valid number sends the code', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    await harness.typePhone('7001234567');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(harness.repository.sentPhones, <String>['+77001234567']);
  });

  testWidgets('a pasted number with +7 keeps only the national part', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.typePhone('+7 700 123 45 67');

    expect(harness.phoneText, '700 123 45 67');
    expect(harness.isSubmitEnabled, isTrue);
  });

  testWidgets('the button is enabled only for a valid number', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    expect(harness.isSubmitEnabled, isFalse);

    await harness.typePhone('700123456');
    expect(harness.isSubmitEnabled, isFalse);

    await harness.typePhone('6001234567');
    expect(harness.isSubmitEnabled, isFalse);

    await harness.typePhone('7001234567');
    expect(harness.isSubmitEnabled, isTrue);

    await harness.typePhone('700123');
    expect(harness.isSubmitEnabled, isFalse);
  });

  testWidgets('sending shows loading and locks the number', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    harness.repository.holdSendCode = true;
    await harness.typePhone('7001234567');

    await harness.submit();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Получить код'), findsNothing);
    expect(harness.isSubmitEnabled, isFalse);
    expect(tester.widget<TextField>(harness.phoneInput).enabled, isFalse);

    await tester.tap(harness.submitButton, warnIfMissed: false);
    await tester.pump();
    expect(harness.repository.sentPhones, hasLength(1));

    harness.repository.heldSendCodes.single.complete(
      const Left<Failure, OtpChallengeEntity>(ServerFailure(statusCode: 500)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.widget<TextField>(harness.phoneInput).enabled, isTrue);
  });

  testWidgets('a failure shows its message in a snackbar', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    harness.repository.sendCodeResult = const Left<Failure, OtpChallengeEntity>(
      ServerFailure(statusCode: 429, code: AuthErrorCodes.tooManyRequests),
    );
    await harness.typePhone('7001234567');

    await harness.submit();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Слишком много попыток. Попробуйте позже'),
      findsOneWidget,
    );
    expect(harness.router.state.uri.path, '/login');
  });

  testWidgets('success opens verify with phone, resendAfter and from', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      initialLocation: '/login?from=%2Fproperties%2F42',
    );
    harness.repository.resendAfter = const Duration(seconds: 45);
    await harness.typePhone('7001234567');

    await harness.submit();
    await tester.pumpAndSettle();

    final Uri uri = harness.router.state.uri;
    expect(uri.path, '/login/verify');
    expect(uri.queryParameters, <String, String>{
      AppRoutes.phoneQuery: '+77001234567',
      AppRoutes.resendAfterQuery: '45',
      AppRoutes.fromQuery: '/properties/42',
    });
    expect(harness.repository.sentPhones, <String>['+77001234567']);
  });

  testWidgets('success without from leaves it out of the query', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    await harness.typePhone('7001234567');

    await harness.submit();
    await tester.pumpAndSettle();

    expect(
      harness.router.state.uri.queryParameters,
      isNot(contains(AppRoutes.fromQuery)),
    );
  });

  testWidgets('shows no back button at the root of the stack', (
    WidgetTester tester,
  ) async {
    await _Harness.pump(tester);

    expect(find.bySemanticsLabel('Назад'), findsNothing);
  });

  testWidgets('a pushed login has a back button that pops', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      initialLocation: '/home',
    );
    harness.router.push('/login');
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(find.text('Home page'), findsOneWidget);
  });
}
