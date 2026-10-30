import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_scope_filter.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_tabs.dart';
import 'package:easy_booking/core/presentation/widgets/navigation/app_week_selector.dart';

void main() {
  testWidgets('AppTabs reports the tapped tab index', (
    WidgetTester tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      _TestApp(
        child: AppTabs(
          labels: const <String>['Обзор', 'Брони', 'Настройки'],
          selectedIndex: 0,
          onSelected: (int index) => selectedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('Брони'));
    await tester.pump();
    expect(selectedIndex, 1);
  });

  testWidgets('AppScopeFilter scrolls and reports selected scope', (
    WidgetTester tester,
  ) async {
    int? selectedIndex;

    await tester.pumpWidget(
      _TestApp(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 220,
            child: AppScopeFilter(
              labels: const <String>[
                'Все объекты',
                'Доступные',
                'Занятые',
              ],
              selectedIndex: 0,
              onSelected: (int index) => selectedIndex = index,
            ),
          ),
        ),
      ),
    );

    await tester.dragUntilVisible(
      find.text('Занятые'),
      find.byType(SingleChildScrollView),
      const Offset(-120, 0),
    );
    await tester.tap(find.text('Занятые'));
    await tester.pump();
    expect(selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppWeekSelector returns the typed day model', (
    WidgetTester tester,
  ) async {
    final List<AppWeekDay> days = _weekDays();
    AppWeekDay? selectedDay;

    await tester.pumpWidget(
      _TestApp(
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 280,
            child: AppWeekSelector(
              days: days,
              selectedDate: days.first.date,
              onSelected: (AppWeekDay day) => selectedDay = day,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('31'));
    await tester.pump();

    expect(selectedDay, same(days[3]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppWeekSelector shows the selected day as a dark pill', (
    WidgetTester tester,
  ) async {
    final List<AppWeekDay> days = _weekDays();
    await tester.pumpWidget(
      _TestApp(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: AppWeekSelector(
              days: days,
              selectedDate: days.first.date,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final Finder selected = find.ancestor(
      of: find.text('Пн'),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is Material && widget.color == AppColors.text,
      ),
    );
    expect(tester.getSize(selected), const Size(48, 68));
    final Text weekday = tester.widget<Text>(find.text('Пн'));
    expect(weekday.style?.color, AppColors.background);
  });

  testWidgets('AppTabs use a dark underline for the selected tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: AppTabs(
          labels: const <String>['Overview', 'Bookings'],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );

    final ColoredBox underline = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(AppTabs),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(underline.color, AppColors.text);
    expect(tester.getSize(find.byWidget(underline)).height, 2);
  });

  testWidgets('navigation selections fit a narrow viewport with large text', (
    WidgetTester tester,
  ) async {
    final List<AppWeekDay> days = _weekDays();
    await tester.pumpWidget(
      _TestApp(
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppTabs(
                    labels: const <String>['Overview', 'Bookings', 'Settings'],
                    selectedIndex: 0,
                    onSelected: (_) {},
                  ),
                  AppScopeFilter(
                    labels: const <String>['All properties', 'Favorites'],
                    selectedIndex: 0,
                    onSelected: (_) {},
                  ),
                  AppWeekSelector(
                    days: days,
                    selectedDate: days.first.date,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

List<AppWeekDay> _weekDays() {
  const List<String> labels = <String>[
    'Пн',
    'Вт',
    'Ср',
    'Чт',
    'Пт',
    'Сб',
    'Вс',
  ];
  return List<AppWeekDay>.generate(7, (int index) {
    return AppWeekDay(
      date: DateTime(2026, 10, 28 + index),
      weekdayLabel: labels[index],
    );
  });
}

final class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }
}
