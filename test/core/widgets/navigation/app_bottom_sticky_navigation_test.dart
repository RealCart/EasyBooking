import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_theme.dart';
import 'package:easy_booking/core/widgets/navigation/app_bottom_navigation.dart';
import 'package:easy_booking/core/widgets/navigation/app_sticky_action_bar.dart';

void main() {
  testWidgets(
    'AppBottomNavigation separates destination and center add callbacks',
    (WidgetTester tester) async {
      int? selectedIndex;
      int addCount = 0;

      await tester.pumpWidget(
        _TestApp(
          bottomNavigationBar: AppBottomNavigation(
            items: _navigationItems(),
            selectedIndex: 0,
            onDestinationSelected: (int index) => selectedIndex = index,
            onAdd: () => addCount += 1,
          ),
        ),
      );

      await tester.tap(find.text('Календарь'));
      await tester.pump();
      expect(selectedIndex, 1);
      expect(addCount, 0);

      await tester.tap(find.bySemanticsLabel('Добавить'));
      await tester.pump();
      expect(selectedIndex, 1);
      expect(addCount, 1);
    },
  );

  testWidgets('AppStickyActionBar rate mode invokes primary action', (
    WidgetTester tester,
  ) async {
    int actionCount = 0;

    await tester.pumpWidget(
      _TestApp(
        bottomNavigationBar: AppStickyActionBar.rate(
          rate: '35 000 ₸',
          rateCaption: 'за ночь',
          primaryLabel: 'Забронировать',
          onPrimaryPressed: () => actionCount += 1,
        ),
      ),
    );

    expect(find.text('35 000 ₸'), findsOneWidget);
    expect(find.text('за ночь'), findsOneWidget);
    await tester.tap(find.text('Забронировать'));
    await tester.pump();
    expect(actionCount, 1);
  });

  testWidgets('AppStickyActionBar flow mode stacks on narrow width', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(300, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int primaryCount = 0;
    int secondaryCount = 0;

    await tester.pumpWidget(
      _TestApp(
        bottomNavigationBar: AppStickyActionBar.flow(
          primaryLabel: 'Продолжить',
          onPrimaryPressed: () => primaryCount += 1,
          secondaryLabel: 'Назад',
          onSecondaryPressed: () => secondaryCount += 1,
        ),
      ),
    );

    await tester.tap(find.text('Продолжить'));
    await tester.tap(find.text('Назад'));
    await tester.pump();

    expect(primaryCount, 1);
    expect(secondaryCount, 1);
    expect(tester.takeException(), isNull);
  });
}

List<AppBottomNavigationItem> _navigationItems() {
  return <AppBottomNavigationItem>[
    AppBottomNavigationItem.destination(
      label: 'Сегодня',
      iconPath: AppAssets.icons.home,
    ),
    AppBottomNavigationItem.destination(
      label: 'Календарь',
      iconPath: AppAssets.icons.calendar,
    ),
    AppBottomNavigationItem.add(
      label: 'Добавить',
      iconPath: AppAssets.icons.plus,
    ),
    AppBottomNavigationItem.destination(
      label: 'Объекты',
      iconPath: AppAssets.icons.building,
    ),
    AppBottomNavigationItem.destination(
      label: 'Профиль',
      iconPath: AppAssets.icons.user,
    ),
  ];
}

final class _TestApp extends StatelessWidget {
  const _TestApp({required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
