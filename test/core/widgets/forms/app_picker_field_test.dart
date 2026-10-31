import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_picker_field.dart';

const List<String> _cities = <String>[
  'Алматы',
  'Астана',
  'Шымкент',
  'Караганда',
  'Актобе',
  'Тараз',
  'Павлодар',
  'Усть-Каменогорск',
  'Семей',
  'Атырау',
  'Костанай',
  'Кызылорда',
  'Уральск',
  'Петропавловск',
  'Актау',
  'Туркестан',
  'Талдыкорган',
  'Кокшетау',
  'Конаев',
];

const AppPickerSheetTexts _texts = AppPickerSheetTexts(
  title: 'Город',
  subtitle: 'Часовой пояс подставим по городу',
  searchHint: 'Найти город',
  searchExample: 'Например, Шымкент',
  emptyTitle: 'Город не найден',
  emptyMessage: 'Проверьте написание. Пока доступны только города Казахстана.',
);

/// An [AppPickerField] of city names inside a [Form], recording every pick.
final class _Harness {
  _Harness(this.tester, this.formKey, this.fieldKey, this.changes);

  final WidgetTester tester;
  final GlobalKey<FormState> formKey;
  final GlobalKey<FormFieldState<String>> fieldKey;
  final List<String> changes;

  static Future<_Harness> pump(
    WidgetTester tester, {
    String? initialValue,
    String? errorText,
    bool enabled = true,
  }) async {
    tester.view
      ..physicalSize = const Size(430, 932)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final GlobalKey<FormFieldState<String>> fieldKey =
        GlobalKey<FormFieldState<String>>();
    final List<String> changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: AppPickerField<String>(
                key: fieldKey,
                label: 'Город и часовой пояс',
                hint: 'Выберите город',
                options: _cities,
                titleOf: (String city) => city,
                subtitleOf: (_) => 'UTC+5',
                valueLabelOf: (String city) => '$city · UTC+5',
                sheetTexts: _texts,
                initialValue: initialValue,
                errorText: errorText,
                enabled: enabled,
                validator: (String? value) =>
                    value == null ? 'Заполните поле' : null,
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    return _Harness(tester, formKey, fieldKey, changes);
  }

  /// Pumps with [selected] already picked and opens the sheet.
  static Future<_Harness> open(
    WidgetTester tester, {
    String? selected = 'Алматы',
  }) async {
    final _Harness harness = await pump(tester, initialValue: selected);
    await harness.openSheet();
    return harness;
  }

  String? get value => fieldKey.currentState!.value;

  Future<void> openSheet() async {
    await tester.tap(find.text('Город и часовой пояс'));
    await tester.pumpAndSettle();
  }

  Finder get sheet => find.byType(BottomSheet);

  Finder get searchInput {
    return find.descendant(of: sheet, matching: find.byType(TextField));
  }

  Finder get list {
    return find.descendant(of: sheet, matching: find.byType(ListView));
  }

  /// Number of rows the list would build, including those off screen.
  int get rowCount {
    final ListView listView = tester.widget<ListView>(list);
    return (listView.childrenDelegate as SliverChildBuilderDelegate)
        .childCount!;
  }

  Finder row(String name) {
    return find
        .ancestor(
          of: find.descendant(of: sheet, matching: find.text(name)),
          matching: find.byType(GestureDetector),
        )
        .first;
  }

  Future<void> search(String query) async {
    await tester.enterText(searchInput, query);
    await tester.pump();
  }

  /// Names of the visible rows, in display order.
  List<String> get shownCities {
    return <String>[
      for (final String city in _cities)
        if (find
            .descendant(of: list, matching: find.text(city))
            .evaluate()
            .isNotEmpty)
          city,
    ];
  }
}

void main() {
  group('field', () {
    testWidgets('shows the label and the hint without a value', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(tester);

      expect(find.text('Город и часовой пояс'), findsOneWidget);
      expect(find.text('Выберите город'), findsOneWidget);
    });

    testWidgets('shows the value label of the initial value', (
      WidgetTester tester,
    ) async {
      await _Harness.pump(tester, initialValue: 'Семей');

      expect(find.text('Семей · UTC+5'), findsOneWidget);
      expect(find.text('Выберите город'), findsNothing);
    });

    testWidgets('a pick updates the value, the label and onChanged', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);
      await harness.openSheet();

      await tester.tap(find.text('Шымкент'));
      await tester.pumpAndSettle();

      expect(harness.sheet, findsNothing);
      expect(harness.value, 'Шымкент');
      expect(harness.changes, <String>['Шымкент']);
      expect(find.text('Шымкент · UTC+5'), findsOneWidget);
    });

    testWidgets('closing the sheet keeps the previous value', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester, selected: 'Семей');

      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();

      expect(harness.sheet, findsNothing);
      expect(harness.value, 'Семей');
      expect(harness.changes, isEmpty);
      expect(find.text('Семей · UTC+5'), findsOneWidget);
    });

    testWidgets('validation shows the message until a value is picked', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester);

      expect(harness.formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Заполните поле'), findsOneWidget);

      await harness.openSheet();
      await tester.tap(find.text('Алматы'));
      await tester.pumpAndSettle();

      expect(harness.formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Заполните поле'), findsNothing);
    });

    testWidgets('shows errorText, with the validator message on top', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(
        tester,
        errorText: 'Проверьте поле',
      );
      expect(find.text('Проверьте поле'), findsOneWidget);

      harness.formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Заполните поле'), findsOneWidget);
      expect(find.text('Проверьте поле'), findsNothing);
    });

    testWidgets('a disabled field does not open the sheet', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.pump(tester, enabled: false);

      await tester.tap(find.text('Город и часовой пояс'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(harness.sheet, findsNothing);
    });
  });

  group('sheet', () {
    testWidgets('shows the texts and a scrollable list of every option', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      expect(find.text('Город'), findsOneWidget);
      expect(find.text('Часовой пояс подставим по городу'), findsOneWidget);
      expect(find.text('Найти город'), findsOneWidget);
      expect(find.text('Например, Шымкент'), findsOneWidget);
      expect(harness.rowCount, 19);
      expect(find.text('Конаев'), findsNothing);
      expect(find.text('UTC+5'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Конаев'),
        300,
        scrollable: find.descendant(
          of: harness.list,
          matching: find.byType(Scrollable),
        ),
      );

      expect(find.text('Конаев'), findsOneWidget);
    });

    testWidgets('does not focus the search field on open', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      expect(
        tester.widget<TextField>(harness.searchInput).focusNode?.hasFocus ??
            false,
        isFalse,
      );
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('search is case-insensitive', (WidgetTester tester) async {
      final _Harness harness = await _Harness.open(tester);

      await harness.search('АЛМ');

      expect(harness.shownCities, <String>['Алматы']);
    });

    testWidgets('search matches a substring and keeps the display order', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      await harness.search('ка');

      expect(harness.shownCities, <String>['Караганда', 'Усть-Каменогорск']);
      expect(harness.rowCount, 2);
    });

    testWidgets('search treats «ё» as «е»', (WidgetTester tester) async {
      final _Harness harness = await _Harness.open(tester);

      await harness.search('сёмей');
      expect(harness.shownCities, <String>['Семей']);

      await harness.search('ШЫМКЁНТ');
      expect(harness.shownCities, <String>['Шымкент']);
    });

    testWidgets('search trims spaces and matches the hyphen literally', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      await harness.search('  астана  ');
      expect(harness.shownCities, <String>['Астана']);

      await harness.search('усть-');
      expect(harness.shownCities, <String>['Усть-Каменогорск']);

      await harness.search('   ');
      expect(harness.rowCount, 19);
    });

    testWidgets('no match shows the empty state; «Очистить поиск» resets', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      await harness.search('Лондон');

      expect(find.text('Город не найден'), findsOneWidget);
      expect(
        find.text(
          'Проверьте написание. Пока доступны только города Казахстана.',
        ),
        findsOneWidget,
      );
      expect(harness.list, findsOneWidget);
      expect(harness.shownCities, isEmpty);

      await tester.tap(find.text('Очистить поиск'));
      await tester.pump();

      expect(find.text('Город не найден'), findsNothing);
      expect(
        tester.widget<TextField>(harness.searchInput).controller!.text,
        isEmpty,
      );
      expect(harness.rowCount, 19);
    });

    testWidgets('the clear button in the field restores the full list', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);
      await harness.search('астана');

      await tester.tap(find.bySemanticsLabel('Очистить поиск'));
      await tester.pump();

      expect(harness.rowCount, 19);
    });

    testWidgets('tapping the subtitle of a row also picks it', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      await tester.tap(
        find.descendant(
          of: harness.row('Астана'),
          matching: find.text('UTC+5'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.value, 'Астана');
    });

    testWidgets('a filtered row is picked', (WidgetTester tester) async {
      final _Harness harness = await _Harness.open(tester);
      await harness.search('кокш');

      await tester.tap(find.text('Кокшетау'));
      await tester.pumpAndSettle();

      expect(harness.value, 'Кокшетау');
    });

    testWidgets('a scrim tap above the sheet keeps the value', (
      WidgetTester tester,
    ) async {
      // The sheet stops at the safe area, so the status bar shows the scrim.
      tester.view.padding = const FakeViewPadding(top: 62);
      final _Harness harness = await _Harness.open(tester);
      expect(tester.getTopLeft(harness.sheet).dy, greaterThanOrEqualTo(62));

      await tester.tapAt(const Offset(215, 20));
      await tester.pumpAndSettle();

      expect(harness.sheet, findsNothing);
      expect(harness.value, 'Алматы');
      expect(harness.changes, isEmpty);
    });

    testWidgets('the selected option shows a check and a bolder title', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester);

      expect(
        find.descendant(
          of: harness.row('Алматы'),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: harness.row('Астана'),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
      Text title(String name) => tester.widget<Text>(
        find.descendant(of: harness.sheet, matching: find.text(name)),
      );
      expect(title('Алматы').style!.fontWeight, FontWeight.w600);
      expect(title('Астана').style!.fontWeight, FontWeight.w500);
    });

    testWidgets('without a value no row has a check', (
      WidgetTester tester,
    ) async {
      final _Harness harness = await _Harness.open(tester, selected: null);

      expect(
        find.descendant(of: harness.list, matching: find.byType(SvgPicture)),
        findsNothing,
      );
    });

    testWidgets('a selected option below the fold is scrolled into view', (
      WidgetTester tester,
    ) async {
      await _Harness.open(tester, selected: 'Конаев');

      expect(find.text('Конаев').hitTestable(), findsOneWidget);
    });
  });
}
