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
import 'package:easy_booking/core/utils/extensions/context_extensions.dart';

/// Texts of the bottom sheet opened by [AppPickerField].
final class AppPickerSheetTexts {
  const AppPickerSheetTexts({
    required this.title,
    required this.searchHint,
    required this.emptyTitle,
    required this.emptyMessage,
    this.subtitle,
    this.searchExample,
    this.clearSearchLabel = 'Очистить поиск',
    this.closeLabel = 'Закрыть',
  });

  final String title;
  final String? subtitle;
  final String searchHint;

  /// Shown under [searchHint] while the query is empty.
  final String? searchExample;

  /// Shown when no option matches the query.
  final String emptyTitle;
  final String emptyMessage;
  final String clearSearchLabel;
  final String closeLabel;
}

/// A read-only form field that opens a searchable bottom sheet of [options]
/// and keeps the picked option as its `FormField` value.
///
/// Inside a `Form` it is validated by [validator] like a text field; read
/// the value through a `GlobalKey<FormFieldState<T>>`. The sheet completes
/// without a change when it is closed, dismissed, or dragged down.
final class AppPickerField<T extends Object> extends FormField<T> {
  AppPickerField({
    required this.label,
    required this.hint,
    required this.options,
    required this.titleOf,
    required this.sheetTexts,
    this.valueLabelOf,
    this.subtitleOf,
    this.errorText,
    this.onChanged,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (FormFieldState<T> field) {
           return (field as _AppPickerFieldState<T>)._buildField();
         },
       );

  final String label;

  /// Shown while no option is picked.
  final String hint;
  final List<T> options;

  /// Row title in the sheet; the search matches it.
  final String Function(T option) titleOf;

  /// Row subtitle in the sheet.
  final String Function(T option)? subtitleOf;

  /// Text of the picked option in the field; [titleOf] when omitted.
  final String Function(T option)? valueLabelOf;
  final AppPickerSheetTexts sheetTexts;

  /// An external error, such as a server field error. The validator's
  /// message takes precedence.
  final String? errorText;

  /// Called after the user picks an option.
  final ValueChanged<T>? onChanged;

  @override
  FormFieldState<T> createState() => _AppPickerFieldState<T>();
}

final class _AppPickerFieldState<T extends Object> extends FormFieldState<T> {
  static const double _minHeight = 72;

  AppPickerField<T> get _field => widget as AppPickerField<T>;

  Future<void> _open() async {
    context.hideKeyboard();
    final T? picked = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      // `--color-text` at the 40% `--opacity-disabled` used by the design.
      barrierColor: AppColors.text.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => _AppPickerSheet<T>(
        options: _field.options,
        selected: value,
        titleOf: _field.titleOf,
        subtitleOf: _field.subtitleOf,
        texts: _field.sheetTexts,
      ),
    );
    if (picked == null || !mounted) {
      return;
    }
    didChange(picked);
    _field.onChanged?.call(picked);
  }

  Widget _buildField() {
    final T? value = this.value;
    final String? valueLabel = value == null
        ? null
        : (_field.valueLabelOf ?? _field.titleOf)(value);
    final String? errorText = this.errorText ?? _field.errorText;
    final bool hasError = errorText != null;
    final bool isEnabled = _field.enabled;
    final VoidCallback? onTap = isEnabled ? _open : null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: <String>[
        _field.label,
        valueLabel ?? _field.hint,
        ?errorText,
      ].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Opacity(
              opacity: isEnabled ? 1 : 0.4,
              child: Container(
                constraints: const BoxConstraints(minHeight: _minHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(
                    color: hasError ? AppColors.error : AppColors.border,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.field),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: <Widget>[
                    Text(
                      _field.label,
                      style: AppTypography.caption.copyWith(
                        color: hasError
                            ? AppColors.error
                            : AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      valueLabel ?? _field.hint,
                      style: AppTypography.bodyLarge.copyWith(
                        color: valueLabel == null
                            ? AppColors.secondaryText
                            : AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (errorText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              errorText,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// The searchable list of options; pops with the tapped option.
final class _AppPickerSheet<T extends Object> extends StatefulWidget {
  const _AppPickerSheet({
    required this.options,
    required this.selected,
    required this.titleOf,
    required this.subtitleOf,
    required this.texts,
    super.key,
  });

  final List<T> options;
  final T? selected;
  final String Function(T option) titleOf;
  final String Function(T option)? subtitleOf;
  final AppPickerSheetTexts texts;

  @override
  State<_AppPickerSheet<T>> createState() => _AppPickerSheetState<T>();
}

final class _AppPickerSheetState<T extends Object>
    extends State<_AppPickerSheet<T>> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late String _query;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(_handleQueryChanged);
    _scrollController = ScrollController();
    _query = '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
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

  /// Scrolls the selected option into the middle of the list when it opens
  /// below the fold. Rows have a minimum height, so the offset is estimated.
  void _revealSelected() {
    final T? selected = widget.selected;
    if (!mounted || selected == null || !_scrollController.hasClients) {
      return;
    }
    final int index = widget.options.indexOf(selected);
    if (index < 0) {
      return;
    }
    final ScrollPosition position = _scrollController.position;
    final double rowHeight = MediaQuery.textScalerOf(
      context,
    ).scale(_OptionRow.minHeight);
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

  List<T> get _visibleOptions {
    if (_query.isEmpty) {
      return widget.options;
    }
    return widget.options
        .where(
          (T option) => _normalize(widget.titleOf(option)).contains(_query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = math.max(
      MediaQuery.viewInsetsOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );
    final List<T> options = _visibleOptions;
    final AppPickerSheetTexts texts = widget.texts;

    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _DragHandle(),
            _SheetHeader(
              title: texts.title,
              subtitle: texts.subtitle,
              closeLabel: texts.closeLabel,
              onClose: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pageGutter,
                AppSpacing.large,
                AppSizes.pageGutter,
                AppSpacing.small,
              ),
              child: AppSearchField(
                controller: _searchController,
                hint: texts.searchHint,
                subtitle: texts.searchExample,
                clearSemanticLabel: texts.clearSearchLabel,
              ),
            ),
            Expanded(
              child: options.isEmpty
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
                          title: texts.emptyTitle,
                          message: texts.emptyMessage,
                          actionLabel: texts.clearSearchLabel,
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
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final T option = options[index];
                        return _OptionRow(
                          title: widget.titleOf(option),
                          subtitle: widget.subtitleOf?.call(option),
                          isSelected: option == widget.selected,
                          onTap: () => Navigator.of(context).pop(option),
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
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
    required this.onClose,
  });

  final String title;
  final String? subtitle;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
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
                    title,
                    style: AppTypography.sectionTitle.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
              ],
            ),
          ),
          AppIconButton(
            icon: const Icon(Icons.close, size: AppSizes.iconAppBar),
            semanticLabel: closeLabel,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// An option row, following the `AppProfileMenuItem` metrics with a narrow
/// selection slot that lines up with the close button.
final class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  static const double minHeight = 77;
  static const double _verticalPadding = 17;
  static const double _selectionSlotWidth = 24;

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    return Semantics(
      button: true,
      selected: isSelected,
      label: <String>[title, ?subtitle].join(', '),
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
                      title,
                      style: AppTypography.action.copyWith(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
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
