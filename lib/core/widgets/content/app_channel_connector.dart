import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/core/widgets/actions/app_text_button.dart';
import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:flutter_svg/svg.dart';

class AppChannelConnector extends StatelessWidget {
  const AppChannelConnector({
    required this.title,
    this.onTap,
    super.key,
  });

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          spacing: 12.0,
          children: <Widget>[
            SvgPicture.asset(AppAssets.icons.calendar),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.primaryText.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    "iCal calendar link",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.compactBody.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            AppTextButton.accent(
              label: "Connect",
              onPressed: () {},
              labelColor: AppColors.text,
            ),
          ],
        ),
      ),
    );
  }
}
