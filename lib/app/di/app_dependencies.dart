import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/router/app_router.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';
import 'package:easy_booking/core/utils/network/api_client.dart';
import 'package:easy_booking/core/utils/network/api_config.dart';
import 'package:easy_booking/core/utils/network/auth_interceptor.dart';
import 'package:easy_booking/core/utils/network/dio_factory.dart';
import 'package:easy_booking/core/utils/session/auth_session.dart';
import 'package:easy_booking/core/utils/session/session_storage.dart';
import 'package:easy_booking/core/utils/storage/preferences_storage.dart';
import 'package:easy_booking/core/utils/storage/secure_storage.dart';

/// The single composition root. Registrations are in dependency order:
/// storage → session → clients → sources → repositories → use cases →
/// BLoCs → router.
abstract final class AppDependencies {
  static final GetIt _getIt = GetIt.instance;

  /// Registers everything and waits for the asynchronous dependencies.
  /// Call once, before `runApp`.
  static Future<void> init() async {
    _registerStorage();
    _registerSession();
    _registerClients();
    _registerRouter();
    await _getIt.allReady();
  }

  /// Disposes every registration. Intended for tests.
  static Future<void> reset() => _getIt.reset();

  /// Available after [init] completes.
  static GoRouter get router => _getIt<GoRouter>();

  static void _registerStorage() {
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

  static void _registerSession() {
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

  static void _registerClients() {
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
          ],
        ),
      );
    }, dispose: (ApiClient client) => client.close());
  }

  static void _registerRouter() {
    _getIt.registerLazySingleton<GoRouter>(
      () => AppRouter.create(session: _getIt<AuthSession>()),
      dispose: (GoRouter router) => router.dispose(),
    );
  }
}
