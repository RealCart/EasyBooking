import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';

import 'package:easy_booking/app/theme/app_radii.dart';

final class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    required this.height,
    this.borderRadius = AppRadii.pill,
    this.color = AppColors.skeletonLight,
    this.width = double.infinity,
    super.key,
  });

  final double height;
  final double width;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
