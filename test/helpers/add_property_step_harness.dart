import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_text_field.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_add_property_draft_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/publish_property_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_channels_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/save_add_property_details_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/add_property_bloc/add_property_bloc.dart';

import 'fake_property_management_repository.dart';

/// Helpers for the screen tests of the «Добавить квартиру» steps.
///
/// Each step is pumped under its own [BlocProvider], as its `wrappedRoute`
/// would, inside a small [GoRouter] whose other routes only show where the
/// router went.
abstract final class AddPropertyStepHarness {
  /// The 430 × 932 phone of the design.
  static void usePhoneSize(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// A route page that shows its location as `route:<uri>`.
  static Widget destination(GoRouterState state) {
    return Scaffold(body: Text('route:${state.uri}'));
  }

  /// [step] under a new [AddPropertyBloc] over [repository] that loads the
  /// draft, like the step's `wrappedRoute`.
  static Widget provide(
    FakePropertyManagementRepository repository,
    Widget step,
  ) {
    return BlocProvider<AddPropertyBloc>(
      create: (_) => AddPropertyBloc(
        getDraft: GetAddPropertyDraftUsecase(repository),
        saveDetails: SaveAddPropertyDetailsUsecase(repository),
        saveChannels: SaveAddPropertyChannelsUsecase(repository),
        publish: PublishPropertyUsecase(repository),
      )..add(const AddPropertyStarted()),
      child: step,
    );
  }

  /// Pumps an app over [routes] at [initialLocation].
  static Future<GoRouter> pump(
    WidgetTester tester, {
    required String initialLocation,
    required List<RouteBase> routes,
    bool settle = true,
  }) async {
    usePhoneSize(tester);
    final GoRouter router = GoRouter(
      initialLocation: initialLocation,
      routes: routes,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  static String location(GoRouter router) => router.state.uri.toString();

  /// The editable input of the [AppTextField] labelled [label].
  static Finder input(String label) {
    return find.descendant(
      of: find.widgetWithText(AppTextField, label),
      matching: find.byType(EditableText),
    );
  }

  /// The text in the field labelled [label].
  static String textOf(WidgetTester tester, String label) {
    return tester.widget<EditableText>(input(label)).controller.text;
  }

  /// Types [text] into the field labelled [label], replacing its value.
  static Future<void> enter(
    WidgetTester tester,
    String label,
    String text,
  ) async {
    await tester.ensureVisible(input(label));
    await tester.enterText(input(label), text);
    await tester.pump();
  }

  /// The footer button labelled [label]; only found while not loading.
  static Finder button(String label) {
    return find.widgetWithText(FilledButton, label);
  }

  static bool isEnabled(WidgetTester tester, String label) {
    return tester.widget<FilledButton>(button(label)).onPressed != null;
  }

  static Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
