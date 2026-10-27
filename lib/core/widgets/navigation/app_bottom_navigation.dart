import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

final class AppBottomNavigationItem {
  const AppBottomNavigationItem.destination({
    required this.label,
    required this.iconPath,
  }) : isAddAction = false;

  const AppBottomNavigationItem.add({
    required this.label,
    required this.iconPath,
  }) : isAddAction = true;

  final String label;
  final String iconPath;
  final bool isAddAction;
}

final class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAdd,
    super.key,
  }) : assert(items.length == 5),
       assert(selectedIndex >= 0),
       assert(selectedIndex < items.length),
       assert(selectedIndex != 2);

  final List<AppBottomNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    assert(
      items[2].isAddAction &&
          items.where((AppBottomNavigationItem item) {
                return item.isAddAction;
              }).length ==
              1,
    );
    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: AppSpacing.xSmall),
          child: SizedBox(
            height: 66,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(items.length, (int index) {
                final AppBottomNavigationItem item = items[index];
                if (item.isAddAction) {
                  return Expanded(
                    child: _AddNavigationItem(item: item, onPressed: onAdd),
                  );
                }
                return Expanded(
                  child: _DestinationNavigationItem(
                    item: item,
                    isSelected: index == selectedIndex,
                    onPressed: () => onDestinationSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DestinationNavigationItem extends StatelessWidget {
  const _DestinationNavigationItem({
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  final AppBottomNavigationItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.accent : AppColors.secondaryText;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.small),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.asset(
                item.iconPath,
                width: AppSizes.iconNavigation,
                height: AppSizes.iconNavigation,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: color,
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _AddNavigationItem extends StatelessWidget {
  const _AddNavigationItem({required this.item, required this.onPressed});

  final AppBottomNavigationItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Tooltip(
            message: item.label,
            child: SizedBox.square(
              dimension: AppSizes.touchTarget,
              child: Material(
                color: AppColors.text,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadii.field),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item.iconPath,
                    width: AppSizes.iconNavigation,
                    height: AppSizes.iconNavigation,
                    colorFilter: const ColorFilter.mode(
                      AppColors.background,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
