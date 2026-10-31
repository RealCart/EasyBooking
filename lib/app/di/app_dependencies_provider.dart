import 'package:flutter/widgets.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';

/// Makes [AppDependencies] available to the whole widget tree. Wraps the app
/// once, at the root, in `main`.
///
/// ```dart
/// final AppDependencies dependencies = AppDependenciesProvider.of(context);
/// final SendCodeUsecase sendCode = dependencies.getDep<SendCodeUsecase>();
/// ```
final class AppDependenciesProvider extends InheritedWidget {
  const AppDependenciesProvider({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  /// The closest [AppDependencies], or `null` when no provider is above
  /// [context].
  static AppDependencies? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppDependenciesProvider>()
        ?.dependencies;
  }

  /// The closest [AppDependencies]. Throws when no provider is above
  /// [context], which means the app was started without one.
  static AppDependencies of<T>(BuildContext context) {
    final AppDependencies? dependencies = maybeOf(context);
    if (dependencies == null) {
      throw FlutterError(
        'AppDependenciesProvider.of() was called with a context that has no '
        'AppDependenciesProvider above it.',
      );
    }
    return dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesProvider oldWidget) {
    return !identical(dependencies, oldWidget.dependencies);
  }
}
