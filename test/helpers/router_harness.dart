import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/auth_tokens.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_bottom_navigation.dart';
import 'package:easy_booking/features/auth/data/repository/auth_repository_impl.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';
import 'package:easy_booking/features/auth/presentation/bloc/account_setup_bloc/account_setup_bloc.dart';
import 'package:easy_booking/features/auth/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:easy_booking/features/auth/presentation/bloc/verify_code_bloc/verify_code_bloc.dart';

import 'fake_auth_remote.dart';
import 'fake_session_storage.dart';

const AuthTokens testTokens = AuthTokens(accessToken: 'access');

/// The real app router over an [AuthSession] backed by a fake storage.
///
/// The auth routes create their BLoCs through `GetIt.instance`, so the
/// harness registers them there over a real [AuthRepositoryImpl] with a
/// [FakeAuthRemote] and the harness session. GetIt is reset in tear-down.
final class RouterHarness {
  RouterHarness._(
    this.tester,
    this.storage,
    this.session,
    this.remote,
    this.router,
  );

  final WidgetTester tester;
  final FakeSessionStorage storage;
  final AuthSession session;
  final FakeAuthRemote remote;
  final GoRouter router;

  /// Builds the app router and pumps it in a `MaterialApp.router`.
  ///
  /// The router, the session and the GetIt registrations are disposed in
  /// tear-down.
  static Future<RouterHarness> pump(
    WidgetTester tester, {
    bool signedIn = true,
    bool accountSetupPending = false,
    String? initialLocation,
  }) async {
    final FakeSessionStorage storage = FakeSessionStorage();
    final AuthSession session = AuthSession(sessionStorage: storage);
    addTearDown(session.dispose);
    if (signedIn) {
      await session.signIn(
        testTokens,
        isAccountSetupPending: accountSetupPending,
      );
    }
    final FakeAuthRemote remote = FakeAuthRemote();
    registerAuthDependencies(session: session, remote: remote);

    final GoRouter router = AppRouter.create(
      session: session,
      initialLocation: initialLocation,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    return RouterHarness._(tester, storage, session, remote, router);
  }

  /// Registers the auth repository, use cases and BLoC factories in
  /// `GetIt.instance` and resets it in tear-down.
  static void registerAuthDependencies({
    required AuthSession session,
    required FakeAuthRemote remote,
  }) {
    final GetIt getIt = GetIt.instance;
    addTearDown(getIt.reset);
    getIt
      ..registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remote: remote, session: session),
      )
      ..registerLazySingleton<SendCodeUsecase>(
        () => SendCodeUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<VerifyCodeUsecase>(
        () => VerifyCodeUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<CreateAccountUsecase>(
        () => CreateAccountUsecase(getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUsecase>(
        () => SignOutUsecase(getIt<AuthRepository>()),
      )
      ..registerFactory<LoginBloc>(
        () => LoginBloc(sendCode: getIt<SendCodeUsecase>()),
      )
      ..registerFactory<VerifyCodeBloc>(
        () => VerifyCodeBloc(
          verifyCode: getIt<VerifyCodeUsecase>(),
          sendCode: getIt<SendCodeUsecase>(),
        ),
      )
      ..registerFactory<AccountSetupBloc>(
        () => AccountSetupBloc(
          createAccount: getIt<CreateAccountUsecase>(),
          signOut: getIt<SignOutUsecase>(),
        ),
      );
  }

  /// The location of the top-most route, including the query. Unlike
  /// `currentConfiguration.uri`, it includes routes opened with `push`.
  String get location => router.state.uri.toString();

  Future<void> go(String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  Finder get bottomNavigation => find.byType(AppBottomNavigation);

  /// Taps the bottom navigation item labelled [label].
  Future<void> tapTab(String label) async {
    await tester.tap(
      find.descendant(of: bottomNavigation, matching: find.text(label)),
    );
    await tester.pumpAndSettle();
  }

  int get selectedItemIndex {
    return tester.widget<AppBottomNavigation>(bottomNavigation).selectedIndex;
  }
}
