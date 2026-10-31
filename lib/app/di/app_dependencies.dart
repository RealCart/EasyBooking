import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:meta/meta.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/core/utils/network/interceptors/error_interceptor.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/api_config.dart';
import 'package:easy_booking/core/utils/network/interceptors/auth_interceptor.dart';
import 'package:easy_booking/core/utils/network/dio_factory.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';
import 'package:easy_booking/features/auth/data/repository/auth_repository_impl.dart';
import 'package:easy_booking/features/auth/data/sources/remote/auth_remote.dart';
import 'package:easy_booking/features/auth/domain/repository/auth_repository.dart';
import 'package:easy_booking/features/auth/domain/usecases/create_account_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/send_code_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:easy_booking/features/auth/domain/usecases/verify_code_usecase.dart';

/// The single composition root.
///
/// Owns a private GetIt container, so nothing is reachable through a global
/// locator. The presentation layer resolves use cases with [getDep] through
/// `AppDependenciesProvider.of(context)`. Registrations are in dependency
/// order:
/// storage → session → clients → sources → repositories → use cases → router.
///
/// BLoCs are not registered: each screen creates its own in
/// `GoRouterWrapper.wrappedRoute` from the use cases resolved here.
final class AppDependencies {
  AppDependencies._(this._getIt);

  /// Wraps a container that already holds the use cases (and the router, if
  /// read), so tests can register fakes without [init].
  @visibleForTesting
  AppDependencies.fromContainer(GetIt getIt) : this._(getIt);

  final GetIt _getIt;

  /// Registers everything and waits for the asynchronous dependencies.
  /// Call once, before `runApp`.
  static Future<AppDependencies> init() async {
    final AppDependencies dependencies = AppDependencies._(
      GetIt.asNewInstance(),
    );
    dependencies
      .._registerStorage()
      .._registerSession()
      .._registerClients()
      .._registerSources()
      .._registerRepositories()
      .._registerUsecases()
      .._registerRouter();
    await dependencies._getIt.allReady();
    return dependencies;
  }

  /// The registered [T]. Screens resolve use cases only; repositories, data
  /// sources, storage, and clients are not for presentation.
  T getDep<T extends Object>() => _getIt<T>();

  void _registerStorage() {
    _getIt
      ..registerSingletonAsync<PreferencesStorage>(
        PreferencesStorageImpl.create,
      )
      ..registerLazySingleton<SecureStorage>(
        () => const SecureStorageImpl(storage: FlutterSecureStorage()),
      )
      ..registerLazySingleton<SessionStorage>(
        () => SessionStorageImpl(
          secureStorage: _getIt<SecureStorage>(),
          preferences: _getIt<PreferencesStorage>(),
        ),
      );
  }

  void _registerSession() {
    _getIt.registerSingletonAsync<AuthSession>(
      () async {
        final AuthSession session = AuthSession(
          sessionStorage: _getIt<SessionStorage>(),
        );
        await session.restore();
        return session;
      },
      dependsOn: <Type>[PreferencesStorage],
      dispose: (AuthSession session) => session.dispose(),
    );
  }

  void _registerClients() {
    _getIt.registerLazySingleton<ApiClient>(() {
      final ApiConfig config = ApiConfig.fromEnvironment();
      if (config.baseUrl.isEmpty) {
        AppLogger.warning(
          'API_BASE_URL is not set; pass it with --dart-define',
        );
      }
      return ApiClientImpl(
        dio: createDio(
          config: config,
          interceptors: <Interceptor>[
            AuthInterceptor(session: _getIt<AuthSession>()),
            // Last, so it sees the original error after `AuthInterceptor`.
            const ErrorInterceptor(),
          ],
        ),
      );
    }, dispose: (ApiClient client) => client.close());
  }

  void _registerSources() {
    _getIt.registerLazySingleton<AuthRemote>(
      () => AuthRemoteImpl(apiClient: _getIt<ApiClient>()),
    );
  }

  void _registerRepositories() {
    _getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: _getIt<AuthRemote>(),
        session: _getIt<AuthSession>(),
      ),
    );
  }

  void _registerUsecases() {
    _getIt
      ..registerLazySingleton<SendCodeUsecase>(
        () => SendCodeUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<VerifyCodeUsecase>(
        () => VerifyCodeUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<CreateAccountUsecase>(
        () => CreateAccountUsecase(_getIt<AuthRepository>()),
      )
      ..registerLazySingleton<SignOutUsecase>(
        () => SignOutUsecase(_getIt<AuthRepository>()),
      );
  }

  void _registerRouter() {
    _getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(session: _getIt<AuthSession>()),
      dispose: (GoRouter router) => router.dispose(),
    );
  }
}
