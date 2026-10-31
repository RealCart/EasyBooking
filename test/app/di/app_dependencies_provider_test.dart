import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:easy_booking/app/di/app_dependencies.dart';
import 'package:easy_booking/app/di/app_dependencies_provider.dart';

/// Records the dependencies it reads and how often it was rebuilt.
final class _Reader extends StatelessWidget {
  const _Reader({required this.onBuild});

  final ValueChanged<AppDependencies> onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(AppDependenciesProvider.of(context));
    return const SizedBox.shrink();
  }
}

void main() {
  late AppDependencies dependencies;

  setUp(() {
    final GetIt getIt = GetIt.asNewInstance();
    addTearDown(getIt.reset);
    dependencies = AppDependencies.fromContainer(getIt);
  });

  testWidgets('of returns the provided dependencies', (
    WidgetTester tester,
  ) async {
    final List<AppDependencies> reads = <AppDependencies>[];

    await tester.pumpWidget(
      AppDependenciesProvider(
        dependencies: dependencies,
        child: _Reader(onBuild: reads.add),
      ),
    );

    expect(reads, <AppDependencies>[dependencies]);
  });

  testWidgets('maybeOf returns null without a provider', (
    WidgetTester tester,
  ) async {
    late AppDependencies? found;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          found = AppDependenciesProvider.maybeOf(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(found, isNull);
  });

  testWidgets('of throws a FlutterError without a provider', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_Reader(onBuild: (_) {}));

    expect(tester.takeException(), isA<FlutterError>());
  });

  testWidgets('dependents rebuild only when the dependencies change', (
    WidgetTester tester,
  ) async {
    final List<AppDependencies> reads = <AppDependencies>[];
    final Widget reader = _Reader(onBuild: reads.add);
    final AppDependencies other = AppDependencies.fromContainer(
      GetIt.asNewInstance(),
    );

    await tester.pumpWidget(
      AppDependenciesProvider(dependencies: dependencies, child: reader),
    );
    await tester.pumpWidget(
      AppDependenciesProvider(dependencies: dependencies, child: reader),
    );
    expect(reads, <AppDependencies>[dependencies]);

    await tester.pumpWidget(
      AppDependenciesProvider(dependencies: other, child: reader),
    );
    expect(reads, <AppDependencies>[dependencies, other]);
  });
}
