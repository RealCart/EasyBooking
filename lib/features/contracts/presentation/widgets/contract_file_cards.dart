import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_text_action.dart';

/// The scanned identity document on «Проверим данные гостя»: a bordered
/// card with «Заменить».
final class ContractIdentityDocumentCard extends StatelessWidget {
  const ContractIdentityDocumentCard({
    required this.fileName,
    required this.details,
    required this.onReplace,
    super.key,
  });

  final String fileName;
  final String details;

  /// Hides «Заменить» when `null`.
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onReplace = this.onReplace;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.media),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: <Widget>[
            const _DocumentIcon(
              background: AppColors.surface,
              borderRadius: AppRadii.field,
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _FileText(
                name: fileName,
                details: details,
                nameStyle: AppTypography.primaryText.copyWith(
                  fontSize: 15,
                  height: 20 / 15,
                  color: AppColors.text,
                ),
              ),
            ),
            if (onReplace != null) ...<Widget>[
              const SizedBox(width: AppSpacing.small),
              ContractTextAction(
                label: 'Заменить',
                semanticLabel: 'Заменить документ',
                onPressed: onReplace,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The contract file on «Условия и подпись»: a filled card with «Открыть».
final class ContractDocumentPreview extends StatelessWidget {
  const ContractDocumentPreview({
    required this.title,
    required this.details,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String details;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.media),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: <Widget>[
            const _DocumentIcon(
              background: AppColors.background,
              borderRadius: AppSpacing.xSmall,
              hasBorder: true,
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _FileText(
                name: title,
                details: details,
                nameStyle: AppTypography.action.copyWith(
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            ContractTextAction(
              label: 'Открыть',
              semanticLabel: 'Открыть договор',
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

/// The contract PDF on «Договор · статус»: a row between dividers.
final class ContractPdfRow extends StatelessWidget {
  const ContractPdfRow({
    required this.title,
    required this.details,
    required this.onOpen,
    super.key,
  });

  final String title;
  final String details;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SizedBox(
                  width: 44,
                  height: 52,
                  child: Center(
                    child: Text(
                      'PDF',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _FileText(
                name: title,
                details: details,
                nameStyle: AppTypography.action.copyWith(
                  color: AppColors.text,
                  height: 18 / 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            ContractTextAction(
              label: 'Открыть',
              semanticLabel: 'Открыть PDF договора',
              onPressed: onOpen,
            ),
          ],
        ),
      ),
    );
  }
}

final class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({
    required this.background,
    required this.borderRadius,
    this.hasBorder = false,
  });

  final Color background;
  final double borderRadius;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: hasBorder ? Border.all(color: AppColors.border) : null,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: SizedBox(
          width: 48,
          height: 56,
          child: Center(
            child: SvgPicture.asset(
              AppAssets.icons.documentTextSmall,
              width: 26,
              height: 26,
            ),
          ),
        ),
      ),
    );
  }
}

final class _FileText extends StatelessWidget {
  const _FileText({
    required this.name,
    required this.details,
    required this.nameStyle,
  });

  final String name;
  final String details;
  final TextStyle nameStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        ),
        const SizedBox(height: 3),
        Text(
          details,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
