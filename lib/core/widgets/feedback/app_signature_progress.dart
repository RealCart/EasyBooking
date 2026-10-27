import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppSignatureStepStatus { draft, sent, signed }

final class AppSignatureStep {
  const AppSignatureStep({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final AppSignatureStepStatus status;
}

final class AppSignatureProgress extends StatelessWidget {
  const AppSignatureProgress({
    required this.documentTitle,
    required this.steps,
    super.key,
  });

  final String documentTitle;
  final List<AppSignatureStep> steps;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: const BorderRadius.all(
          Radius.circular(AppRadii.card),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(documentTitle, style: AppTypography.primaryText),
            const SizedBox(height: AppSpacing.large),
            for (int index = 0; index < steps.length; index++)
              _SignatureStepRow(
                step: steps[index],
                isLast: index == steps.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

final class _SignatureStepRow extends StatelessWidget {
  const _SignatureStepRow({required this.step, required this.isLast});

  final AppSignatureStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (step.status) {
      AppSignatureStepStatus.draft => AppColors.secondaryText,
      AppSignatureStepStatus.sent => AppColors.info,
      AppSignatureStepStatus.signed => AppColors.success,
    };
    final IconData statusIcon = switch (step.status) {
      AppSignatureStepStatus.draft => Icons.edit_outlined,
      AppSignatureStepStatus.sent => Icons.send_outlined,
      AppSignatureStepStatus.signed => Icons.check,
    };

    return Semantics(
      label: '${step.title}. ${step.subtitle}. ${step.status.name}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: AppSizes.touchTarget,
            child: Column(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: AppSizes.iconNavigation,
                    child: Icon(
                      statusIcon,
                      color: AppColors.background,
                      size: AppSizes.iconInline,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: AppSpacing.xxLarge,
                    color: AppColors.border,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(step.title, style: AppTypography.action),
                  Text(step.subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
