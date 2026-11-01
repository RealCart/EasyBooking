import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/features/guests/domain/entity/guest_document_entity.dart';
import 'package:easy_booking/features/guests/presentation/widgets/guest_labels.dart';

/// The guest's identity document with its check status and «Открыть», or a
/// note that nothing was uploaded when [document] is `null`.
final class GuestDocumentRow extends StatelessWidget {
  const GuestDocumentRow({
    required this.document,
    required this.onOpen,
    super.key,
  });

  static const double _thumbnailWidth = 42;
  static const double _thumbnailHeight = 50;
  static const double _thumbnailRadius = 6;

  final GuestDocumentEntity? document;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final GuestDocumentEntity? document = this.document;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.pageGutter,
        vertical: 14,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: _thumbnailWidth,
            height: _thumbnailHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.all(
                Radius.circular(_thumbnailRadius),
              ),
            ),
            child: SvgPicture.asset(
              AppAssets.icons.file,
              width: 20,
              height: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  document?.title ?? 'Документ не загружен',
                  style: AppTypography.action.copyWith(
                    height: 18 / 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  document?.statusDetails ??
                      'Гость загрузит его по ссылке из договора',
                  style: AppTypography.caption.copyWith(
                    height: 18 / 12,
                    color: document?.statusColor ?? AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (document != null) ...<Widget>[
            const SizedBox(width: AppSpacing.medium),
            ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSizes.touchTarget,
                minHeight: AppSizes.touchTarget,
              ),
              child: Center(
                child: Semantics(
                  button: true,
                  child: AppTextButton.underlined(
                    label: 'Открыть',
                    onPressed: onOpen,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
