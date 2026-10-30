import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_picker_sheet.dart';

/// Opens the picker with `showCityPickerSheet` from a button and keeps the
/// value it completes with.
final class _Launcher {
  _Launcher(this.tester);

  final WidgetTester tester;
  CityEntity? result;
  bool isCompleted = false;

  static Future<_Launcher> open(
    WidgetTester tester, {
    CityEntity? selected = KazakhstanCities.almaty,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final _Launcher launcher = _Launcher(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  launcher.result = await showCityPickerSheet(
                    context,
                    selected: selected,
                  );
                  launcher.isCompleted = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return launcher;
  }

  Finder get sheet => find.byType(CityPickerSheet);

  Finder get searchInput {
    return find.descendant(of: sheet, matching: find.byType(TextField));
  }

  Finder get cityList {
    return find.descendant(of: sheet, matching: find.byType(ListView));
  }

  /// Number of rows the list would build, including those off screen.
  int get rowCount {
    final ListView list = tester.widget<ListView>(cityList);
    return (list.childrenDelegate as SliverChildBuilderDelegate).childCount!;
  }

  Finder row(String name) {
    return find
        .ancestor(of: find.text(name), matching: find.byType(GestureDetector))
        .first;
  }

  Future<void> search(String query) async {
    await tester.enterText(searchInput, query);
    await tester.pump();
  }

  /// Names of the visible rows, in display order.
  List<String> get shownCities {
    return <String>[
      for (final CityEntity city in KazakhstanCities.all)
        if (find
            .descendant(of: cityList, matching: find.text(city.name))
            .evaluate()
            .isNotEmpty)
          city.name,
    ];
  }
}

void main() {
  testWidgets('shows the title, search field and a scrollable list of 19', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    expect(find.text('Город'), findsOneWidget);
    expect(find.text('Часовой пояс подставим по городу'), findsOneWidget);
    expect(find.text('Найти город'), findsOneWidget);
    expect(find.text('Например, Шымкент'), findsOneWidget);
    expect(launcher.rowCount, 19);
    expect(find.text('Конаев'), findsNothing);
    expect(find.text('UTC+5'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Конаев'),
      300,
      scrollable: find.descendant(
        of: launcher.cityList,
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.text('Конаев'), findsOneWidget);
  });

  testWidgets('does not focus the search field on open', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    expect(
      tester.widget<TextField>(launcher.searchInput).focusNode?.hasFocus ??
          false,
      isFalse,
    );
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('search is case-insensitive', (WidgetTester tester) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await launcher.search('АЛМ');

    expect(launcher.shownCities, <String>['Алматы']);
  });

  testWidgets('search matches a substring and keeps the display order', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await launcher.search('ка');

    expect(launcher.shownCities, <String>['Караганда', 'Усть-Каменогорск']);
    expect(launcher.rowCount, 2);
  });

  testWidgets('search treats «ё» as «е»', (WidgetTester tester) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await launcher.search('сёмей');
    expect(launcher.shownCities, <String>['Семей']);

    await launcher.search('ШЫМКЁНТ');
    expect(launcher.shownCities, <String>['Шымкент']);
  });

  testWidgets('search trims spaces and matches the hyphen literally', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await launcher.search('  астана  ');
    expect(launcher.shownCities, <String>['Астана']);

    await launcher.search('усть-');
    expect(launcher.shownCities, <String>['Усть-Каменогорск']);

    await launcher.search('   ');
    expect(launcher.rowCount, 19);
  });

  testWidgets('no match shows the empty state; «Очистить поиск» resets', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await launcher.search('Лондон');

    expect(find.text('Город не найден'), findsOneWidget);
    expect(
      find.text('Проверьте написание. Пока доступны только города Казахстана.'),
      findsOneWidget,
    );
    expect(launcher.cityList, findsOneWidget);
    expect(find.text('Алматы'), findsNothing);

    await tester.tap(find.text('Очистить поиск'));
    await tester.pump();

    expect(find.text('Город не найден'), findsNothing);
    expect(
      tester.widget<TextField>(launcher.searchInput).controller!.text,
      isEmpty,
    );
    expect(launcher.rowCount, 19);
  });

  testWidgets('the clear button in the field restores the full list', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);
    await launcher.search('астана');

    await tester.tap(find.bySemanticsLabel('Очистить поиск'));
    await tester.pump();

    expect(launcher.rowCount, 19);
  });

  testWidgets('tapping a row returns that city and closes the sheet', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await tester.tap(find.text('Шымкент'));
    await tester.pumpAndSettle();

    expect(launcher.isCompleted, isTrue);
    expect(launcher.result, KazakhstanCities.shymkent);
    expect(launcher.sheet, findsNothing);
  });

  testWidgets('tapping the time zone part of a row also selects it', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await tester.tap(
      find.descendant(of: launcher.row('Астана'), matching: find.text('UTC+5')),
    );
    await tester.pumpAndSettle();

    expect(launcher.result, KazakhstanCities.astana);
  });

  testWidgets('a filtered row returns its city', (WidgetTester tester) async {
    final _Launcher launcher = await _Launcher.open(tester);
    await launcher.search('кокш');

    await tester.tap(find.text('Кокшетау'));
    await tester.pumpAndSettle();

    expect(launcher.result, KazakhstanCities.kokshetau);
  });

  testWidgets('the close button returns null', (WidgetTester tester) async {
    final _Launcher launcher = await _Launcher.open(tester);

    await tester.tap(find.bySemanticsLabel('Закрыть'));
    await tester.pumpAndSettle();

    expect(launcher.isCompleted, isTrue);
    expect(launcher.result, isNull);
    expect(launcher.sheet, findsNothing);
  });

  testWidgets('a scrim tap above the sheet returns null', (
    WidgetTester tester,
  ) async {
    // The sheet stops at the safe area, so the status bar shows the scrim.
    tester.view.padding = const FakeViewPadding(top: 62);
    final _Launcher launcher = await _Launcher.open(tester);
    expect(tester.getTopLeft(launcher.sheet).dy, greaterThanOrEqualTo(62));

    await tester.tapAt(const Offset(215, 20));
    await tester.pumpAndSettle();

    expect(launcher.isCompleted, isTrue);
    expect(launcher.result, isNull);
  });

  testWidgets('the selected city shows a check and a bolder name', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester);

    expect(
      find.descendant(
        of: launcher.row('Алматы'),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: launcher.row('Астана'),
        matching: find.byType(SvgPicture),
      ),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.text('Алматы')).style!.fontWeight,
      FontWeight.w600,
    );
    expect(
      tester.widget<Text>(find.text('Астана')).style!.fontWeight,
      FontWeight.w500,
    );
  });

  testWidgets('without a selection no row has a check', (
    WidgetTester tester,
  ) async {
    final _Launcher launcher = await _Launcher.open(tester, selected: null);

    expect(
      find.descendant(of: launcher.cityList, matching: find.byType(SvgPicture)),
      findsNothing,
    );
  });

  testWidgets('a selected city below the fold is scrolled into view', (
    WidgetTester tester,
  ) async {
    await _Launcher.open(tester, selected: KazakhstanCities.konaev);

    expect(find.text('Конаев').hitTestable(), findsOneWidget);
  });
}
