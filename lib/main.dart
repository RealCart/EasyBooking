import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/app.dart';
import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';
import 'package:easy_booking/core/utils/bloc/app_bloc_observer.dart';
import 'package:easy_booking/core/utils/logger/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Uncaught asynchronous error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
  Bloc.observer = const AppBlocObserver();

  final AppDependencies dependencies = await AppDependencies.init();

  runApp(
    AppDependenciesProvider(
      dependencies: dependencies,
      child: EasyBookingApp(router: dependencies.getDep<GoRouter>()),
    ),
  );
}
