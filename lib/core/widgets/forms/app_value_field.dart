import 'package:flutter/material.dart';

import 'package:easy_booking/app/theme/app_colors.dart';
import 'package:easy_booking/app/theme/app_radii.dart';
import 'package:easy_booking/app/theme/app_typography.dart';

enum AppValueFieldType { money, time }

class AppValueField extends StatelessWidget {
  const AppValueField({
    required this.type,
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.errorText,
    this.currencySymbol = r'$',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    super.key,
  }) : assert(controller == null || initialValue == null);

  final AppValueFieldType type;
  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? hint;
  final String? errorText;
  final String currencySymbol;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label case final String label) ...<Widget>[
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: type == AppValueFieldType.money
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.datetime,
          textInputAction: TextInputAction.done,
          style: AppTypography.body.copyWith(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixText: type == AppValueFieldType.money ? currencySymbol : null,
            suffixStyle: AppTypography.body.copyWith(color: AppColors.text),
            isDense: true,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: border(AppColors.border),
            disabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.text, 2),
            errorBorder: border(AppColors.error),
            focusedErrorBorder: border(AppColors.error),
          ),
        ),
      ],
    );
  }
}
