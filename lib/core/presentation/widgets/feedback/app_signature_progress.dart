import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppSignatureStepStatus { draft, sent, signed }

final class AppSignatureStep {
  const AppSignatureStep({
    required this.title,
    required this.subtitle,
    required this.status,
    this.statusLabel,
  });

  final String title;
  final String subtitle;
  final AppSignatureStepStatus status;
  final String? statusLabel;
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
    return Semantics(
      label: documentTitle,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final AppSignatureStep step in steps)
              _SignatureStepRow(step: step),
          ],
        ),
      ),
    );
  }
}

final class _SignatureStepRow extends StatelessWidget {
  const _SignatureStepRow({required this.step});

  final AppSignatureStep step;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = switch (step.status) {
      AppSignatureStepStatus.draft => AppColors.info,
      AppSignatureStepStatus.sent => AppColors.warning,
      AppSignatureStepStatus.signed => AppColors.success,
    };
    final String statusLabel = step.statusLabel ?? step.status.name;

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(dimension: 10),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      step.title,
                      style: AppTypography.action.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                    Text(
                      step.subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryText,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Flexible(
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.end,
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    height: 18 / 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
