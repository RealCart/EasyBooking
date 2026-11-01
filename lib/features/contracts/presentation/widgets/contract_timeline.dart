import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// One step of [ContractTimeline].
@immutable
final class ContractTimelineStep {
  const ContractTimelineStep({
    required this.title,
    required this.subtitle,
    this.isPending = false,
  });

  final String title;
  final String subtitle;

  /// A step that has not happened yet: an outlined marker and a warning
  /// colored subtitle.
  final bool isPending;
}

/// «История»: completed steps with a connecting line, oldest first.
final class ContractTimeline extends StatelessWidget {
  const ContractTimeline({required this.steps, super.key});

  final List<ContractTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < steps.length; index++)
          _TimelineRow(
            step: steps[index],
            hasLine: index < steps.length - 1,
          ),
      ],
    );
  }
}

final class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.hasLine});

  static const double _markerSize = 10;

  final ContractTimelineStep step;
  final bool hasLine;

  @override
  Widget build(BuildContext context) {
    final Widget marker = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step.isPending ? AppColors.background : AppColors.success,
        border: step.isPending
            ? Border.all(color: AppColors.warning, width: 2)
            : null,
      ),
      child: const SizedBox.square(dimension: _markerSize),
    );

    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: hasLine ? 66 : 56),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Column(
                  children: <Widget>[
                    // Centers the marker on the first line of the title.
                    const SizedBox(height: (18 - _markerSize) / 2),
                    marker,
                    if (hasLine)
                      const Expanded(
                        child: VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title,
                        style: AppTypography.action.copyWith(
                          color: AppColors.text,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: AppTypography.caption.copyWith(
                          color: step.isPending
                              ? AppColors.warning
                              : AppColors.secondaryText,
                          height: 16 / 12,
                        ),
                      ),
                    ],
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
