import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppFileRow extends StatelessWidget {
  const AppFileRow({
    required this.fileName,
    required this.details,
    super.key,
    this.leading,
    this.action,
    this.onTap,
    this.showDivider = true,
  });

  final String fileName;
  final String details;
  final Widget? leading;
  final Widget? action;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: AppColors.border))
                : null,
          ),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child:
                        leading ??
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.error,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.primaryText.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.compactBody.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: Center(child: action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
