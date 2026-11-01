import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/entity/auth_error_codes.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_details_entity.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_fields.dart';
import 'package:easy_booking/features/profile/domain/entity/update_profile_params_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_details_usecase.dart';
import 'package:easy_booking/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/edit_profile_bloc/edit_profile_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/edit_profile_screen.dart';

import '../../../../helpers/fake_profile_repository.dart';
import 'profile_detail_harness.dart';

typedef _H = ProfileDetailHarness;

/// Pushes [EditProfileScreen] under its own [EditProfileBloc], started as
/// `wrappedRoute` does.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeProfileRepository repository, {
  bool settle = true,
}) {
  return _H.pump(
    tester,
    () => BlocProvider<EditProfileBloc>(
      create: (_) => EditProfileBloc(
        getProfileDetails: GetProfileDetailsUsecase(repository),
        updateProfile: UpdateProfileUsecase(repository),
      )..add(const EditProfileStarted()),
      child: const EditProfileScreen(),
    ),
    settle: settle,
  );
}

final Finder _saveButton = _H.filledButton('Сохранить');

Future<void> _save(WidgetTester tester, {bool settle = true}) async {
  await tester.tap(_saveButton);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  group('EditProfileScreen states', () {
    testWidgets('shows a skeleton and a disabled save while loading', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdDetails = true;

      await _pump(tester, repository, settle: false);

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(_H.isEnabled(tester, _saveButton), isFalse);

      repository.heldDetails.single.complete(
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppSkeleton), findsNothing);
      expect(_H.isEnabled(tester, _saveButton), isTrue);
    });

    testWidgets('fills the form from the loaded details', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      expect(_H.textOf(tester, 'Имя'), 'Бексултан');
      expect(_H.textOf(tester, 'Фамилия'), 'Нишанбек');
      expect(_H.textOf(tester, 'Телефон'), '+7 701 234 56 78');
      expect(_H.textOf(tester, 'Электронная почта'), 'b.nishanbek@gmail.com');
      await tester.ensureVisible(_H.field('Название'));
      expect(_H.textOf(tester, 'Название'), 'EasyBooking Алматы');
      expect(_H.textOf(tester, 'Часовой пояс'), 'UTC +5');
      expect(find.text('Алматы'), findsOneWidget);
      expect(find.text('Бексултан Нишанбек'), findsOneWidget);
    });

    testWidgets('the phone field is read-only', (WidgetTester tester) async {
      await _pump(tester, FakeProfileRepository());

      expect(tester.widget<TextField>(_H.field('Телефон')).readOnly, isTrue);
    });

    testWidgets('a failed first load offers a retry that loads the form', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..detailsResult = const Left<Failure, ProfileDetailsEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Не удалось загрузить профиль'), findsOneWidget);
      expect(find.text('Нет подключения к интернету'), findsOneWidget);
      expect(_H.isEnabled(tester, _saveButton), isFalse);

      repository.detailsResult = const Right<Failure, ProfileDetailsEntity>(
        testProfileDetails,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsNothing);
      expect(_H.textOf(tester, 'Имя'), 'Бексултан');
      expect(repository.detailsCount, 2);
    });

    testWidgets('«Изменить фотографию» says it is coming soon', (
      WidgetTester tester,
    ) async {
      await _pump(tester, FakeProfileRepository());

      await tester.tap(find.text('Изменить фотографию'));
      await tester.pump();

      expect(_H.snackbar('Скоро будет'), findsOneWidget);
    });
  });

  group('EditProfileScreen submit', () {
    testWidgets(
      'an invalid form shows the validator messages and saves nothing',
      (
        WidgetTester tester,
      ) async {
        final FakeProfileRepository repository = FakeProfileRepository();
        await _pump(tester, repository);

        await _H.type(tester, 'Имя', '');
        await _H.type(tester, 'Электронная почта', 'not-an-email');
        await _save(tester);

        expect(find.text('Заполните поле'), findsOneWidget);
        expect(find.text('Проверьте адрес почты'), findsOneWidget);
        expect(repository.updateProfileParams, isEmpty);
        expect(find.text(ProfileDetailHarness.basePage), findsNothing);
      },
    );

    testWidgets('a valid form saves the params and leaves the screen', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository();
      final GoRouter router = await _pump(tester, repository);

      await _H.type(tester, 'Имя', 'Алихан');
      await _H.type(tester, 'Фамилия', 'Сейткали');
      await _H.type(tester, 'Электронная почта', 'a.seitkali@mail.kz');
      await _H.type(tester, 'Название', 'Алихан Апартаменты');
      await _H.tapVisible(tester, find.text('Город'));
      await tester.tap(find.text('Астана'));
      await tester.pumpAndSettle();

      expect(find.text('Астана'), findsOneWidget);
      expect(_H.textOf(tester, 'Часовой пояс'), 'UTC +5');

      await _save(tester);

      expect(repository.updateProfileParams, const <UpdateProfileParamsEntity>[
        UpdateProfileParamsEntity(
          firstName: 'Алихан',
          lastName: 'Сейткали',
          email: 'a.seitkali@mail.kz',
          teamName: 'Алихан Апартаменты',
          city: KazakhstanCities.astana,
        ),
      ]);
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text(ProfileDetailHarness.basePage), findsOneWidget);
      expect(router.state.uri.toString(), '/');
    });

    testWidgets('saving disables the form and ignores another tap', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..holdUpdateProfile = true;
      await _pump(tester, repository);

      await _save(tester, settle: false);
      // The label is replaced by a progress indicator while saving.
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(repository.updateProfileParams, hasLength(1));
      expect(tester.widget<TextField>(_H.field('Имя')).enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.heldUpdateProfile.single.complete(
        const Right<Failure, ProfileDetailsEntity>(testProfileDetails),
      );
      await tester.pumpAndSettle();

      expect(find.text(ProfileDetailHarness.basePage), findsOneWidget);
    });

    testWidgets('server field errors show under their fields until edited', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..updateProfileResult = const Left<Failure, ProfileDetailsEntity>(
          ValidationFailure(
            fieldErrors: <String, String>{
              ProfileFields.email: AuthErrorCodes.invalidEmail,
              ProfileFields.teamName: AuthErrorCodes.required,
            },
          ),
        );
      await _pump(tester, repository);
      await _H.type(tester, 'Имя', 'Алихан');

      await _save(tester);

      expect(find.text('Проверьте адрес почты'), findsOneWidget);
      expect(find.text('Заполните поле'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      // The form keeps what the user typed.
      expect(_H.textOf(tester, 'Имя'), 'Алихан');

      await _H.type(tester, 'Электронная почта', 'b.nishanbek@mail.kz');

      expect(find.text('Проверьте адрес почты'), findsNothing);
      expect(find.text('Заполните поле'), findsOneWidget);
    });

    testWidgets('a general save failure shows a snackbar and stays', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository repository = FakeProfileRepository()
        ..updateProfileResult = const Left<Failure, ProfileDetailsEntity>(
          ConnectionFailure(),
        );
      await _pump(tester, repository);

      await _save(tester);

      expect(_H.snackbar('Нет подключения к интернету'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(_H.isEnabled(tester, _saveButton), isTrue);
    });
  });
}
