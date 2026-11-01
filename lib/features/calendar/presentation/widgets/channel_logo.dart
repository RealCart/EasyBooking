import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A channel's initial on a grey tile, until the channels have real logos.
final class ChannelLogo extends StatelessWidget {
  const ChannelLogo({required this.initial, super.key}) : _isLarge = false;

  /// The 52 px tile at the top of «Канал».
  const ChannelLogo.large({required this.initial, super.key}) : _isLarge = true;

  final String initial;
  final bool _isLarge;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _isLarge
        ? AppTypography.sectionTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          )
        : AppTypography.primaryText.copyWith(
            height: 20 / 16,
            fontWeight: FontWeight.w700,
          );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _isLarge ? 52 : 44,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.media)),
          ),
          child: Center(
            child: Text(
              initial,
              style: style.copyWith(color: AppColors.text),
            ),
          ),
        ),
      ),
    );
  }
}
