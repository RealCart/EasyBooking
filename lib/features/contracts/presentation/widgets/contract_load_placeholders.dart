import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:easy_booking/app/constants/assets/app_assets.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_empty_state.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';
import 'package:easy_booking/core/utils/error/failure.dart';
import 'package:easy_booking/features/contracts/presentation/widgets/contract_labels.dart';

/// Shown while a contract loads for the first time.
final class ContractSkeleton extends StatelessWidget {
  const ContractSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: const <Widget>[
        AppSkeleton(height: 30, width: 260),
        SizedBox(height: AppSpacing.medium),
        AppSkeleton(height: 18, width: 220),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 88, borderRadius: AppRadii.media),
        SizedBox(height: AppSpacing.xLarge),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
        SizedBox(height: AppSpacing.large),
        AppSkeleton(height: 72, borderRadius: AppRadii.field),
      ],
    );
  }
}

/// A failed first load: «Договор не найден» for an unknown id, otherwise
/// the failure text with «Повторить».
final class ContractLoadError extends StatelessWidget {
  const ContractLoadError({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageGutter),
      children: <Widget>[
        if (failure.isContractMissing)
          AppEmptyState(
            title: 'Договор не найден',
            message: 'Возможно, его удалили или ссылка устарела',
            icon: SvgPicture.asset(AppAssets.icons.fileText),
          )
        else
          AppEmptyState(
            title: 'Не удалось загрузить договор',
            message: failure.contractMessage,
            icon: SvgPicture.asset(AppAssets.icons.alertCircle),
            actionLabel: 'Повторить',
            onAction: onRetry,
          ),
      ],
    );
  }
}
