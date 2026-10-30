import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:easy_booking/core/utils/logger/app_logger.dart';

/// Logs errors thrown inside any BLoC/Cubit.
final class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      'Unhandled error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
