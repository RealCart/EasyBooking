import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/features/auth/domain/entity/account_fields.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';
import 'package:easy_booking/features/auth/presentation/screens/account_setup_screen.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_picker_sheet.dart';

import '../../../../helpers/fake_auth_repository.dart';

final class _Harness {
  _Harness(this.tester, this.repository, this.bloc);

  final WidgetTester tester;
  final FakeAuthRepository repository;
  final AccountSetupBloc bloc;

  /// Pumps the screen with a BLoC owned by its provider. [events] are added
  /// before the first build, as if the user had already typed them.
  static Future<_Harness> pump(
    WidgetTester tester, {
    List<AccountSetupEvent> events = const <AccountSetupEvent>[],
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final FakeAuthRepository repository = FakeAuthRepository();
    final AccountSetupBloc bloc = AccountSetupBloc(
      createAccount: CreateAccountUsecase(repository),
      signOut: SignOutUsecase(repository),
    );
    events.forEach(bloc.add);
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<AccountSetupBloc>(
          create: (_) => bloc,
          child: const AccountSetupScreen(),
        ),
      ),
    );
    return _Harness(tester, repository, bloc);
  }

  Finder field(String label) {
    return find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(TextField),
    );
  }

  Finder get submitButton => find.byType(FilledButton);

  Future<void> submit() async {
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();
    await tester.pump();
  }
}

const List<AccountSetupEvent> _validForm = <AccountSetupEvent>[
  AccountFirstNameChanged('Айгерим'),
  AccountLastNameChanged('Садыкова'),
  AccountEmailChanged('aigerim@example.kz'),
  AccountTeamNameChanged('Esentai Stay'),
  AccountCitySelected(KazakhstanCities.almaty),
];

void main() {
  testWidgets('shows the account form', (WidgetTester tester) async {
    await _Harness.pump(tester);

    expect(find.text('Ваш аккаунт'), findsOneWidget);
    expect(find.text('Как к вам обращаться?'), findsOneWidget);
    expect(find.text('Эти данные увидят гости в документах.'), findsOneWidget);
    for (final String label in <String>[
      'Имя',
      'Фамилия',
      'Email для документов',
      'Название команды',
      'Город и часовой пояс',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Выберите город'), findsOneWidget);
    expect(
      find.text('Реквизиты для договоров добавите в настройках'),
      findsOneWidget,
    );
    expect(find.text('Создать аккаунт'), findsOneWidget);
  });

  testWidgets('the email field uses the email keyboard', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    expect(
      tester
          .widget<TextField>(harness.field('Email для документов'))
          .keyboardType,
      TextInputType.emailAddress,
    );
  });

  testWidgets('typing dispatches the field events', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.enterText(harness.field('Имя'), 'Айгерим');
    await tester.enterText(harness.field('Фамилия'), 'Садыкова');
    await tester.enterText(
      harness.field('Email для документов'),
      'aigerim@example.kz',
    );
    await tester.enterText(harness.field('Название команды'), 'Esentai Stay');
    await tester.pump();

    expect(
      harness.bloc.state,
      const AccountSetupState(
        firstName: 'Айгерим',
        lastName: 'Садыкова',
        email: 'aigerim@example.kz',
        teamName: 'Esentai Stay',
      ),
    );
  });

  testWidgets('submitting an empty form shows an error under each field', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await harness.submit();

    expect(find.text('Заполните поле'), findsNWidgets(5));
    expect(harness.repository.createAccountCalls, isEmpty);

    await tester.enterText(harness.field('Имя'), 'Айгерим');
    await tester.pump();

    expect(find.text('Заполните поле'), findsNWidgets(4));
  });

  testWidgets('an invalid email shows its own message', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      events: <AccountSetupEvent>[
        ..._validForm,
        const AccountEmailChanged('aigerim@'),
      ],
    );

    await harness.submit();

    expect(find.text('Проверьте адрес почты'), findsOneWidget);
    expect(find.text('Заполните поле'), findsNothing);
  });

  testWidgets('a server field error shows under its field', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester, events: _validForm);
    harness.repository.createAccountResult = const Left<Failure, void>(
      ValidationFailure(
        fieldErrors: <String, String>{AccountFields.teamName: 'taken'},
      ),
    );

    await harness.submit();

    expect(find.text('Проверьте поле'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a general failure shows a snackbar', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester, events: _validForm);
    harness.repository.createAccountResult = const Left<Failure, void>(
      ServerFailure(statusCode: 500),
    );

    await harness.submit();

    expect(
      find.text('Сервис временно недоступен. Попробуйте позже'),
      findsOneWidget,
    );
  });

  testWidgets('a valid form creates the account with trimmed values', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      events: <AccountSetupEvent>[
        ..._validForm,
        const AccountFirstNameChanged('  Айгерим  '),
      ],
    );

    await harness.submit();

    expect(
      harness.repository.createAccountCalls.single,
      const CreateAccountParams(
        firstName: 'Айгерим',
        lastName: 'Садыкова',
        email: 'aigerim@example.kz',
        teamName: 'Esentai Stay',
        city: KazakhstanCities.almaty,
      ),
    );
  });

  testWidgets('the city field opens the picker and shows the selection', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.text('Город и часовой пояс'));
    await tester.pumpAndSettle();

    expect(find.byType(CityPickerSheet), findsOneWidget);
    expect(find.text('Часовой пояс подставим по городу'), findsOneWidget);

    await tester.tap(find.text('Алматы'));
    await tester.pumpAndSettle();

    expect(find.byType(CityPickerSheet), findsNothing);
    expect(find.text('Алматы · UTC+5'), findsOneWidget);
    expect(find.text('Выберите город'), findsNothing);
    expect(harness.bloc.state.city, KazakhstanCities.almaty);
  });

  testWidgets('closing the picker keeps the previous city', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(
      tester,
      events: const <AccountSetupEvent>[
        AccountCitySelected(KazakhstanCities.semey),
      ],
    );
    expect(find.text('Семей · UTC+5'), findsOneWidget);

    await tester.tap(find.text('Город и часовой пояс'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Закрыть'));
    await tester.pumpAndSettle();

    expect(harness.bloc.state.city, KazakhstanCities.semey);
    expect(find.text('Семей · UTC+5'), findsOneWidget);
  });

  testWidgets('the header back button cancels setup', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pump();

    expect(harness.repository.signOutCount, 1);
  });

  testWidgets('system back cancels setup', (WidgetTester tester) async {
    final _Harness harness = await _Harness.pump(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(harness.repository.signOutCount, 1);
    expect(find.byType(AccountSetupScreen), findsOneWidget);
  });

  testWidgets('a sign-out failure shows a snackbar', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester);
    harness.repository.signOutResult = const Left<Failure, void>(
      StorageFailure(),
    );

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Не удалось сохранить данные на устройстве'),
      findsOneWidget,
    );
  });

  testWidgets('everything is locked while the account is being created', (
    WidgetTester tester,
  ) async {
    final _Harness harness = await _Harness.pump(tester, events: _validForm);
    harness.repository.holdCreateAccount = true;

    await harness.submit();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final String label in <String>[
      'Имя',
      'Фамилия',
      'Email для документов',
      'Название команды',
    ]) {
      expect(
        tester.widget<TextField>(harness.field(label)).enabled,
        isFalse,
        reason: label,
      );
    }

    await tester.tap(find.bySemanticsLabel('Назад'), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.tap(find.text('Город и часовой пояс'), warnIfMissed: false);
    // The loading spinner never settles, so pump past the sheet animation.
    await tester.pump(const Duration(seconds: 1));

    expect(harness.repository.signOutCount, 0);
    expect(find.byType(CityPickerSheet), findsNothing);
    expect(harness.repository.createAccountCalls, hasLength(1));

    harness.repository.heldCreateAccounts.single.complete(
      const Left<Failure, void>(ServerFailure(statusCode: 500)),
    );
    await tester.pump();
    await tester.pump();

    expect(
      tester.widget<TextField>(harness.field('Имя')).enabled,
      isTrue,
    );
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pump();
    expect(harness.repository.signOutCount, 1);
  });
}
