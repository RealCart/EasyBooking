import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/core/presentation/widgets/feedback/app_skeleton.dart';

/// Placeholder of the scope chips, the two stay cards, and the tasks while
/// the overview loads for the first time.
final class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              AppSkeleton(height: 36, width: 104),
              SizedBox(width: AppSpacing.small),
              AppSkeleton(height: 36, width: 96),
              SizedBox(width: AppSpacing.small),
              AppSkeleton(height: 36, width: 124),
            ],
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Row(
            children: <Widget>[
              for (int index = 0; index < 2; index++) ...<Widget>[
                if (index > 0) const SizedBox(width: AppSpacing.large),
                const Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppSkeleton(
                      height: double.infinity,
                      borderRadius: AppRadii.card,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xxLarge),
          const AppSkeleton(height: 20, width: 160),
          const SizedBox(height: AppSpacing.large),
          const AppSkeleton(height: 44, borderRadius: AppRadii.media),
          const SizedBox(height: AppSpacing.medium),
          const AppSkeleton(height: 44, borderRadius: AppRadii.media),
        ],
      ),
    );
  }
}
