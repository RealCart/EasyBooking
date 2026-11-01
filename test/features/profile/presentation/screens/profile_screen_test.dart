import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/profile/domain/entity/profile_entity.dart';
import 'package:easy_booking/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:easy_booking/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:easy_booking/features/profile/presentation/screens/profile_screen.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_profile_repository.dart';
import '../../../../helpers/router_harness.dart';

/// Pumps the screen under its own [ProfileBloc], started as `wrappedRoute`
/// does.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required FakeProfileRepository profiles,
  FakeAuthRepository? auth,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<ProfileBloc>(
        create: (_) => ProfileBloc(
          getProfile: GetProfileUsecase(profiles),
          signOut: SignOutUsecase(auth ?? FakeAuthRepository()),
        )..add(const ProfileRequested()),
        child: const ProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSignOut(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Ещё'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Выйти из аккаунта'));
  await tester.pumpAndSettle();
}

void main() {
  group('ProfileScreen states', () {
    testWidgets('shows the user, the workspace numbers, and the menu', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester, profiles: FakeProfileRepository());

      expect(find.text('БН'), findsOneWidget);
      expect(find.text('Бексултан Нишанбек'), findsOneWidget);
      expect(find.text('Владелец · Алматы'), findsOneWidget);
      expect(find.text('Редактировать профиль'), findsOneWidget);
      expect(find.text('квартиры'), findsOneWidget);
      expect(find.text('в команде'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      for (final String item in <String>[
        'Гости и договоры',
        'Команда и доступ',
        'Уведомления',
        'Безопасность',
        'Помощь',
      ]) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('a failed load keeps the menu and offers a retry', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository()
        ..profileResult = const Left<Failure, ProfileEntity>(
          ConnectionFailure(),
        );
      await _pumpScreen(tester, profiles: profiles);

      expect(find.text('Не удалось загрузить профиль'), findsOneWidget);
      expect(find.text('Гости и договоры'), findsOneWidget);

      profiles.profileResult = const Right<Failure, ProfileEntity>(
        testProfile,
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('Бексултан Нишанбек'), findsOneWidget);
    });

    testWidgets('cancelling the sign-out dialog keeps the session', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      await _pumpScreen(tester, profiles: FakeProfileRepository(), auth: auth);

      await _openSignOut(tester);
      expect(find.text('Выйти из аккаунта?'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(auth.signOutCount, 0);
    });

    testWidgets('confirming signs out', (WidgetTester tester) async {
      final FakeAuthRepository auth = FakeAuthRepository();
      await _pumpScreen(tester, profiles: FakeProfileRepository(), auth: auth);

      await _openSignOut(tester);
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();

      expect(auth.signOutCount, 1);
    });

    testWidgets('a failed sign out shows a snackbar', (
      WidgetTester tester,
    ) async {
      final FakeAuthRepository auth = FakeAuthRepository()
        ..signOutResult = const Left<Failure, void>(StorageFailure());
      await _pumpScreen(tester, profiles: FakeProfileRepository(), auth: auth);

      await _openSignOut(tester);
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();

      expect(
        find.text('Не удалось сохранить данные на устройстве'),
        findsOneWidget,
      );
    });
  });

  group('ProfileScreen navigation', () {
    testWidgets('returning from «Редактировать профиль» reloads the profile', (
      WidgetTester tester,
    ) async {
      final FakeProfileRepository profiles = FakeProfileRepository();
      final GoRouter router = GoRouter(
        initialLocation: AppRoutes.profile.path,
        routes: <RouteBase>[
          GoRoute(
            name: AppRoutes.profile.name,
            path: AppRoutes.profile.path,
            builder: (_, _) => BlocProvider<ProfileBloc>(
              create: (_) => ProfileBloc(
                getProfile: GetProfileUsecase(profiles),
                signOut: SignOutUsecase(FakeAuthRepository()),
              )..add(const ProfileRequested()),
              child: const ProfileScreen(),
            ),
            routes: <RouteBase>[
              GoRoute(
                name: AppRoutes.editProfile.name,
                path: AppRoutes.editProfile.path,
                builder: (_, _) => const Scaffold(body: Text('edit route')),
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
      expect(profiles.profileCount, 1);

      await tester.tap(find.text('Редактировать профиль'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile/edit');

      profiles.profileResult = const Right<Failure, ProfileEntity>(
        ProfileEntity(
          firstName: 'Алихан',
          lastName: 'Сейткали',
          role: ProfileRole.owner,
          city: 'Астана',
          propertyCount: 4,
          teamMemberCount: 2,
          plan: SubscriptionPlan.pro,
        ),
      );
      router.pop();
      await tester.pumpAndSettle();

      expect(profiles.profileCount, 2);
      expect(find.text('Алихан Сейткали'), findsOneWidget);
      expect(find.text('Владелец · Астана'), findsOneWidget);
    });

    testWidgets('the profile tab shows the mock profile', (
      WidgetTester tester,
    ) async {
      await RouterHarness.pump(tester, initialLocation: '/profile');

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Бексултан Нишанбек'), findsOneWidget);
    });

    testWidgets('a menu item opens its screen', (WidgetTester tester) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/profile',
      );

      await tester.tap(find.text('Команда и доступ'));
      await tester.pumpAndSettle();

      expect(harness.location, '/profile/team');
    });

    testWidgets('«Редактировать профиль» opens the edit screen', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/profile',
      );

      await tester.tap(find.text('Редактировать профиль'));
      await tester.pumpAndSettle();

      expect(harness.location, '/profile/edit');
    });

    testWidgets('confirmed sign out returns to login', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await RouterHarness.pump(
        tester,
        initialLocation: '/profile',
      );

      await _openSignOut(tester);
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();

      expect(harness.session.isAuthenticated, isFalse);
      expect(Uri.parse(harness.location).path, '/login');
    });
  });
}
