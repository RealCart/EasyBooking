import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_icon_button.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/forms/app_search_field.dart';
import 'package:easy_booking/features/auth/domain/entity/city_entity.dart';
import 'package:easy_booking/features/auth/domain/entity/kazakhstan_cities.dart';
import 'package:easy_booking/features/auth/presentation/widgets/city_labels.dart';

/// Opens the city picker over the current screen.
///
/// Completes with the tapped city, or `null` when the sheet is dismissed
/// with the close button, a scrim tap, a drag down, or system back.
Future<CityEntity?> showCityPickerSheet(
  BuildContext context, {
  required CityEntity? selected,
}) {
  return showModalBottomSheet<CityEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    // `--color-text` at the 40% `--opacity-disabled` used by the design.
    barrierColor: AppColors.text.withValues(alpha: 0.4),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (_) => CityPickerSheet(selected: selected),
  );
}

final class CityPickerSheet extends StatefulWidget {
  const CityPickerSheet({
    required this.selected,
    this.cities = KazakhstanCities.all,
    super.key,
  });

  final CityEntity? selected;
  final List<CityEntity> cities;

  @override
  State<CityPickerSheet> createState() => _CityPickerSheetState();
}

final class _CityPickerSheetState extends State<CityPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final String query = _normalize(_searchController.text);
    if (query == _query) {
      return;
    }
    setState(() => _query = query);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  /// Scrolls the selected city into the middle of the list when it opens
  /// below the fold. Rows have a minimum height, so the offset is estimated.
  void _revealSelected() {
    final CityEntity? selected = widget.selected;
    if (!mounted || selected == null || !_scrollController.hasClients) {
      return;
    }
    final int index = widget.cities.indexOf(selected);
    if (index < 0) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final double rowHeight = MediaQuery.textScalerOf(
      context,
    ).scale(_CityListItem.minHeight);
    if ((index + 1) * rowHeight <= position.viewportDimension) {
      return;
    }
    final double offset =
        index * rowHeight - (position.viewportDimension - rowHeight) / 2;
    _scrollController.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  /// Case-insensitive, trimmed, with «ё» matched as «е».
  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll('ё', 'е');
  }

  List<CityEntity> get _visibleCities {
    if (_query.isEmpty) {
      return widget.cities;
    }
    return widget.cities
        .where((CityEntity city) => _normalize(city.name).contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );
    final List<CityEntity> cities = _visibleCities;

    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _DragHandle(),
            _SheetHeader(onClose: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pageGutter,
                AppSpacing.large,
                AppSizes.pageGutter,
                AppSpacing.small,
              ),
              child: AppSearchField(
                controller: _searchController,
                hint: 'Найти город',
                subtitle: 'Например, Шымкент',
                clearSemanticLabel: 'Очистить поиск',
              ),
            ),
            Expanded(
              child: cities.isEmpty
                  ? ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pageGutter,
                        AppSpacing.large,
                        AppSizes.pageGutter,
                        AppSpacing.large,
                      ),
                      children: <Widget>[
                        AppEmptyState(
                          title: 'Город не найден',
                          message:
                              'Проверьте написание. Пока доступны только '
                              'города Казахстана.',
                          actionLabel: 'Очистить поиск',
                          onAction: _searchController.clear,
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.pageGutter,
                      ),
                      itemCount: cities.length,
                      itemBuilder: (BuildContext context, int index) {
                        final CityEntity city = cities[index];
                        return _CityListItem(
                          city: city,
                          isSelected: city == widget.selected,
                          onTap: () => Navigator.of(context).pop(city),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.medium,
        bottom: AppSpacing.xSmall,
      ),
      child: Center(
        child: SizedBox(
          width: AppSpacing.xxLarge,
          height: AppSpacing.xSmall,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.pill)),
            ),
          ),
        ),
      ),
    );
  }
}

final class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pageGutter,
        AppSpacing.small,
        AppSpacing.medium,
        0,
      ),
      child: Row(
        spacing: AppSpacing.large,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xSmall,
              children: <Widget>[
                Semantics(
                  header: true,
                  child: Text(
                    'Город',
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  'Часовой пояс подставим по городу',
                  style: AppTypography.body.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: const Icon(Icons.close, size: AppSizes.iconAppBar),
            semanticLabel: 'Закрыть',
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// A city row, following the `AppProfileMenuItem` metrics with a narrow
/// selection slot that lines up with the close button.
final class _CityListItem extends StatelessWidget {
  const _CityListItem({
    required this.city,
    required this.isSelected,
    required this.onTap,
  });

  static const double minHeight = 77;
  static const double _verticalPadding = 17;
  static const double _selectionSlotWidth = 24;

  final CityEntity city;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${city.name}, ${city.utcOffsetLabel}',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(vertical: _verticalPadding),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            spacing: AppSpacing.large,
            children: <Widget>[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: <Widget>[
                    Text(
                      city.name,
                      style: AppTypography.action.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      city.utcOffsetLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: _selectionSlotWidth,
                child: isSelected
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: SvgPicture.asset(
                          AppAssets.icons.checkSmall,
                          width: AppSizes.iconAction,
                          height: AppSizes.iconAction,
                          colorFilter: const ColorFilter.mode(
                            AppColors.text,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
