import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/router/app_routes.dart';
import 'package:easy_booking/core/widgets/navigation/app_bottom_navigation.dart';

/// Hosts the four tab branches and the bottom navigation.
///
/// The navigation has five items: the third is the add action, which opens
/// a flow instead of a branch, so item indexes are mapped to branch indexes.
final class AppShellScreen extends StatelessWidget {
  const AppShellScreen({required this.navigationShell, super.key});

  static const int _addItemIndex = 2;

  final StatefulNavigationShell navigationShell;

  static final List<AppBottomNavigationItem> _items = <AppBottomNavigationItem>[
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        items: _items,
        selectedIndex: _itemIndexFor(navigationShell.currentIndex),
        onDestinationSelected: _onDestinationSelected,
        onAdd: () => context.pushNamed(AppRoutes.addProperty.name),
      ),
    );
  }

  void _onDestinationSelected(int itemIndex) {
    final int branchIndex = _branchIndexFor(itemIndex);
    // Tapping the active tab returns it to its first screen.
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  static int _itemIndexFor(int branchIndex) {
    return branchIndex < _addItemIndex ? branchIndex : branchIndex + 1;
  }

  static int _branchIndexFor(int itemIndex) {
    return itemIndex < _addItemIndex ? itemIndex : itemIndex - 1;
  }
}
