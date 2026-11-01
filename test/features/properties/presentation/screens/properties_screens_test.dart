import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_large_listing_card.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_property_row.dart';
import 'package:easy_booking/core/utils/either/either.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/properties/domain/entity/property_entity.dart';
import 'package:easy_booking/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:easy_booking/features/properties/domain/usecases/set_property_favorite_usecase.dart';
import 'package:easy_booking/features/properties/presentation/bloc/properties_bloc/properties_bloc.dart';
import 'package:easy_booking/features/properties/presentation/screens/favorite_properties_screen.dart';
import 'package:easy_booking/features/properties/presentation/screens/properties_screen.dart';
import 'package:easy_booking/features/properties/presentation/widgets/favorite_property_card.dart';

import '../../../../helpers/fake_properties_repository.dart';
import '../../../../helpers/router_harness.dart';

/// The 430 × 932 phone of the design, so lazy lists build every row.
void _usePhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1290, 2796)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<RouterHarness> _pumpAt(WidgetTester tester, String location) {
  _usePhoneSize(tester);
  return RouterHarness.pump(tester, initialLocation: location);
}

Future<void> _pumpDirect(
  WidgetTester tester,
  Widget screen,
  FakePropertiesRepository repository,
) async {
  _usePhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<PropertiesBloc>(
        create: (_) => PropertiesBloc(
          getProperties: GetPropertiesUsecase(repository),
          setFavorite: SetPropertyFavoriteUsecase(repository),
        )..add(const PropertiesRequested()),
        child: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PropertiesScreen', () {
    testWidgets('lists the mock apartments with counts and statuses', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties');

      expect(find.byType(PropertiesScreen), findsOneWidget);
      expect(find.text('4 квартиры в Алматы'), findsOneWidget);
      expect(find.text('Все · 4'), findsOneWidget);
      expect(find.text('Свободны · 2'), findsOneWidget);
      expect(find.text('Заняты · 2'), findsOneWidget);
      expect(find.text('Esentai City · квартира 84'), findsOneWidget);
      expect(find.text('Заезд сегодня'), findsOneWidget);
      expect(find.text('Mega Towers · 126'), findsOneWidget);
      expect(find.text('Свободна до 25 октября'), findsOneWidget);
      expect(find.text('Заезд сегодня, 18:30'), findsOneWidget);
    });

    testWidgets('a chip shows only free apartments', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties');

      await tester.tap(find.text('Свободны · 2'));
      await tester.pumpAndSettle();

      expect(find.byType(AppLargeListingCard), findsOneWidget);
      expect(find.byType(AppPropertyRow), findsOneWidget);
      expect(find.textContaining('Esentai City'), findsNothing);
    });

    testWidgets('search narrows the list and explains an empty result', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties');

      await tester.enterText(find.byType(EditableText), 'samal');
      await tester.pumpAndSettle();
      expect(find.text('Samal Residence · квартира 12'), findsOneWidget);
      expect(find.byType(AppPropertyRow), findsNothing);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('Ничего не нашли'), findsOneWidget);
    });

    testWidgets('sorting by price puts the cheapest first', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties');

      await tester.tap(find.bySemanticsLabel('Сортировка'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сначала дешевле'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<AppLargeListingCard>(find.byType(AppLargeListingCard))
            .title,
        'Mega Towers · квартира 126',
      );
    });

    testWidgets('the heart of the large card removes the favorite', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties');
      final Finder heart = find.descendant(
        of: find.byType(AppLargeListingCard),
        matching: find.byType(AppSavedIconButton),
      );
      expect(tester.widget<AppSavedIconButton>(heart).isSaved, isTrue);

      await tester.tap(heart);
      await tester.pumpAndSettle();

      expect(tester.widget<AppSavedIconButton>(heart).isSaved, isFalse);
    });

    testWidgets('a row opens its property and back keeps the tab', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(tester, '/properties');

      await tester.tap(find.text('Mega Towers · 126'));
      await tester.pumpAndSettle();
      expect(harness.location, '/properties/mega-towers-126');

      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();
      expect(harness.location, '/properties');
    });

    testWidgets('the heart in the header opens favorites', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(tester, '/properties');

      await tester.tap(find.bySemanticsLabel('Избранные'));
      await tester.pumpAndSettle();

      expect(harness.location, '/properties/favorites');
      expect(find.byType(FavoritePropertiesScreen), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (WidgetTester tester) async {
      final FakePropertiesRepository repository = FakePropertiesRepository()
        ..propertiesResult = const Left<Failure, List<PropertyEntity>>(
          ConnectionFailure(),
        );
      await _pumpDirect(tester, const PropertiesScreen(), repository);

      expect(find.text('Не удалось загрузить объекты'), findsOneWidget);

      repository.propertiesResult = Right<Failure, List<PropertyEntity>>(
        testProperties(),
      );
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();

      expect(find.text('2 квартиры в Алматы'), findsOneWidget);
    });
  });

  group('FavoritePropertiesScreen', () {
    testWidgets('shows the favorites of the mock source', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties/favorites');

      expect(find.text('Быстрый доступ'), findsOneWidget);
      expect(find.byType(FavoritePropertyCard), findsNWidgets(2));
      expect(find.text('Esentai City · 84'), findsOneWidget);
      expect(find.text('Свободна до 25 окт'), findsOneWidget);
    });

    testWidgets('removing a heart removes the card', (
      WidgetTester tester,
    ) async {
      await _pumpAt(tester, '/properties/favorites');

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(FavoritePropertyCard, 'Esentai City · 84'),
          matching: find.byType(AppSavedIconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FavoritePropertyCard), findsOneWidget);
      expect(find.text('Esentai City · 84'), findsNothing);
    });

    testWidgets('the favorites calendar opens the occupancy', (
      WidgetTester tester,
    ) async {
      final RouterHarness harness = await _pumpAt(
        tester,
        '/properties/favorites',
      );

      await tester.tap(find.text('Календарь избранных'));
      await tester.pumpAndSettle();

      expect(harness.location, '/calendar/occupancy');
    });

    testWidgets('with no favorites explains the heart', (
      WidgetTester tester,
    ) async {
      final FakePropertiesRepository repository = FakePropertiesRepository()
        ..propertiesResult = Right<Failure, List<PropertyEntity>>(
          <PropertyEntity>[
            testProperties()[1],
          ],
        );
      await _pumpDirect(tester, const FavoritePropertiesScreen(), repository);

      expect(find.text('Пока нет избранных'), findsOneWidget);
      expect(find.text('Календарь избранных'), findsNothing);
    });
  });
}
