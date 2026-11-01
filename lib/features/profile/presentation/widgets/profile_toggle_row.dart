import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_sizes.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// The 44 × 26 switch of the settings screens: dark when on, grey when off.
final class ProfileSwitch extends StatelessWidget {
  const ProfileSwitch({
    required this.value,
    required this.onChanged,
    super.key,
  });

  static const double _width = 44;
  static const double _height = 26;
  static const double _knobSize = 20;
  static const Duration _duration = Duration(milliseconds: 150);

  final bool value;

  /// Disables the switch when `null`.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? onChanged = this.onChanged;
    final bool isEnabled = onChanged != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: AnimatedContainer(
        duration: _duration,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.text : AppColors.border,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
        ),
        child: AnimatedAlign(
          duration: _duration,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: const SizedBox.square(
            dimension: _knobSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A setting with a title, a hint, and a [ProfileSwitch]. The whole row
/// toggles the value.
final class ProfileToggleRow extends StatelessWidget {
  const ProfileToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Disables the row when `null`.
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool>? onChanged = this.onChanged;
    final String? subtitle = this.subtitle;

    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: onChanged != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged(!value),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageGutter,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              border: showDivider
                  ? const Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 18 / 14,
                          color: AppColors.text,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            height: 18 / 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ProfileSwitch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
