import 'package:easy_booking/core/widgets/actions/app_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

class AppFileRow extends StatelessWidget {
  const AppFileRow({
    required this.fileName,
    required this.details,
    this.onTap,
    this.onReplcae,
    super.key,
  });

  final String fileName;
  final String? details;
  final VoidCallback? onTap;
  final VoidCallback? onReplcae;

  @override
  Widget build(BuildContext context) {
    final Widget fileDetails = Row(
      children: <Widget>[
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.field)),
          ),
          child: SizedBox(
            width: 48,
            height: 56,
            child: Center(
              child: IconTheme(
                data: const IconThemeData(color: AppColors.text, size: 26),
                child: SvgPicture.asset(
                  AppAssets.icons.documentTextSmall,
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.primaryText.copyWith(
                  fontSize: 15,
                  height: 20 / 15,
                  color: AppColors.text,
                ),
              ),
              if (details case final String details) ...<Widget>[
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.media),
          border: .all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Row(
              children: <Widget>[
                Expanded(child: fileDetails),
                const SizedBox(width: AppSpacing.small),
                AppTextButton.underlined(
                  label: "Replace",
                  onPressed: onReplcae,
                  labelColor: AppColors.text,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
