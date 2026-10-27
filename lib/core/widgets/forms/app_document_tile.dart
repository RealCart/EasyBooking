import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/widgets/actions/app_button.dart';

class AppDocumentTile extends StatelessWidget {
  const AppDocumentTile({
    required this.fileName,
    this.details,
    this.actionLabel = 'Remove',
    this.onAction,
    this.leading = const Icon(Icons.description_outlined),
    super.key,
  });

  final String fileName;
  final String? details;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final Widget fileDetails = Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconTheme(
            data: const IconThemeData(color: AppColors.accent, size: 22),
            child: leading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.primaryText.copyWith(
                  color: AppColors.text,
                ),
              ),
              if (details case final String details)
                Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth < 280 && onAction != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  fileDetails,
                  const SizedBox(height: 8),
                  AppButton(
                    label: actionLabel,
                    onPressed: onAction,
                    variant: AppButtonVariant.text,
                    isExpanded: true,
                  ),
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: fileDetails),
                if (onAction != null) ...<Widget>[
                  const SizedBox(width: 8),
                  AppButton(
                    label: actionLabel,
                    onPressed: onAction,
                    variant: AppButtonVariant.text,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
