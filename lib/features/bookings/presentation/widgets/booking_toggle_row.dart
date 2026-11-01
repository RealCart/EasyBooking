import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_spacing.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

/// A setting with a title, a hint and a switch, such as «Создать договор
/// после брони». The whole row toggles [value].
final class BookingToggleRow extends StatelessWidget {
  const BookingToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String? subtitle = this.subtitle;
    final VoidCallback? onTap = enabled ? () => onChanged(!value) : null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: <String>[title, ?subtitle].join(', '),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTypography.action.copyWith(
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
                  const SizedBox(width: AppSpacing.large),
                  _Switch(value: value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 44 × 26 track with a 20 px knob of the design.
final class _Switch extends StatelessWidget {
  const _Switch({required this.value});

  static const Duration _duration = Duration(milliseconds: 150);

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.text : AppColors.border,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
      ),
      child: AnimatedAlign(
        duration: _duration,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: const SizedBox.square(
          dimension: 20,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
