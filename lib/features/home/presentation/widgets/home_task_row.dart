import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';
import 'package:easy_booking/core/presentation/widgets/actions/app_text_button.dart';
import 'package:easy_booking/core/presentation/widgets/content/app_task_row.dart';
import 'package:easy_booking/core/utils/date_formatter.dart';
import 'package:easy_booking/features/home/presentation/mock/home_mock_data.dart';

/// A task before arrival: a contract offers a reminder, a preparation shows
/// its deadline.
final class HomeTaskRow extends StatelessWidget {
  const HomeTaskRow({
    required this.task,
    required this.onTap,
    required this.onRemind,
    super.key,
  });

  final HomeTaskMock task;
  final VoidCallback onTap;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final DateTime? dueAt = task.dueAt;

    return AppTaskRow(
      title: task.title,
      subtitle: task.subtitle,
      onTap: onTap,
      leading: SvgPicture.asset(
        switch (task.kind) {
          HomeTaskKind.contract => AppAssets.icons.documentTextSmall,
          HomeTaskKind.preparation => AppAssets.icons.checkSmall,
        },
        width: AppSizes.iconAppBar,
        height: AppSizes.iconAppBar,
      ),
      action: switch (task.kind) {
        HomeTaskKind.contract => AppTextButton.accent(
          label: 'Напомнить',
          labelColor: AppColors.text,
          onPressed: onRemind,
        ),
        HomeTaskKind.preparation when dueAt != null => Text(
          'До ${DateFormatter.time(dueAt)}',
          style: AppTypography.textAccent.copyWith(color: AppColors.text),
        ),
        HomeTaskKind.preparation => null,
      },
    );
  }
}
