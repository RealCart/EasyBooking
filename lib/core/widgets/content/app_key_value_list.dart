import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

@immutable
class AppKeyValueRow {
  const AppKeyValueRow({
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
}

class AppKeyValueList extends StatelessWidget {
  const AppKeyValueList({
    required this.rows,
    super.key,
    this.padding = EdgeInsets.zero,
    this.showDividers = true,
  });

  final List<AppKeyValueRow> rows;
  final EdgeInsetsGeometry padding;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 0; index < rows.length; index++)
            _KeyValueRowView(
              row: rows[index],
              showDivider: showDividers && index < rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _KeyValueRowView extends StatelessWidget {
  const _KeyValueRowView({required this.row, required this.showDivider});

  final AppKeyValueRow row;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isNarrow = constraints.maxWidth < 260;
          final Widget label = Text(
            row.label,
            maxLines: isNarrow ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: AppColors.secondaryText,
            ),
          );
          final Widget value =
              row.valueWidget ??
              Text(
                row.value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: isNarrow ? TextAlign.start : TextAlign.end,
                style: AppTypography.body.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                label,
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: value),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: label),
              const SizedBox(width: 16),
              Expanded(
                child: Align(alignment: Alignment.topRight, child: value),
              ),
            ],
          );
        },
      ),
    );
  }
}
